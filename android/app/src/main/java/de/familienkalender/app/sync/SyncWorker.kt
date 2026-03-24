package de.familienkalender.app.sync

import android.content.Context
import android.util.Log
import androidx.work.*
import de.familienkalender.app.FamilienkalenderApp
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.util.concurrent.TimeUnit

class SyncWorker(
    context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    override suspend fun doWork(): Result {
        val app = applicationContext as FamilienkalenderApp

        if (!app.tokenManager.isLoggedIn) return Result.success()

        Log.d(TAG, "Starting sync...")

        return try {
            replayPendingChanges(app)
            refreshAllRepositories(app)
            Log.d(TAG, "Sync completed successfully")
            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Sync failed", e)
            Result.retry()
        }
    }

    private suspend fun refreshAllRepositories(app: FamilienkalenderApp) {
        app.memberRepository.refresh()
        app.categoryRepository.refresh()
        app.eventRepository.refresh()
        app.todoRepository.refresh()
        app.recipeRepository.refresh()
        app.shoppingRepository.refresh()
    }

    private suspend fun replayPendingChanges(app: FamilienkalenderApp) {
        val pendingDao = app.database.pendingChangeDao()
        val changes = pendingDao.getAll()

        if (changes.isEmpty()) return
        Log.d(TAG, "Replaying ${changes.size} pending changes")

        val client = app.retrofitClient.okHttpClient
        val baseUrl = app.tokenManager.serverUrl.trimEnd('/')
        val token = app.tokenManager.token ?: return
        val mediaType = "application/json".toMediaType()

        for (change in changes) {
            try {
                val url = "$baseUrl/${change.endpoint}"
                val body = change.payload?.toRequestBody(mediaType)

                val request = buildRequest(change.action, url, body, mediaType, token) ?: continue
                val response = client.newCall(request).execute()

                if (response.isSuccessful || response.code == 404 || response.code == 409) {
                    pendingDao.deleteById(change.id)
                    Log.d(TAG, "Replayed change ${change.id}: ${change.action} ${change.endpoint}")
                } else {
                    Log.w(TAG, "Failed to replay change ${change.id}: HTTP ${response.code}")
                }
                response.close()
            } catch (e: Exception) {
                Log.w(TAG, "Failed to replay change ${change.id}", e)
            }
        }
    }

    private fun buildRequest(
        action: String,
        url: String,
        body: okhttp3.RequestBody?,
        mediaType: okhttp3.MediaType,
        token: String
    ): Request? {
        val builder = Request.Builder()
            .url(url)
            .header("Authorization", "Bearer $token")

        return when (action) {
            "CREATE" -> builder.post(body ?: return null).build()
            "UPDATE" -> builder.put(body ?: return null).build()
            "PATCH" -> builder.patch(body ?: "{}".toRequestBody(mediaType)).build()
            "DELETE" -> builder.delete().build()
            else -> null
        }
    }

    companion object {
        private const val TAG = "SyncWorker"
        private const val SYNC_WORK_NAME = "familienkalender_sync"

        fun enqueuePeriodicSync(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()

            val syncRequest = PeriodicWorkRequestBuilder<SyncWorker>(15, TimeUnit.MINUTES)
                .setConstraints(constraints)
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 1, TimeUnit.MINUTES)
                .build()

            WorkManager.getInstance(context)
                .enqueueUniquePeriodicWork(SYNC_WORK_NAME, ExistingPeriodicWorkPolicy.KEEP, syncRequest)
        }
    }
}

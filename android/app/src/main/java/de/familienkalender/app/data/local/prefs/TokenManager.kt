package de.familienkalender.app.data.local.prefs

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import de.familienkalender.app.BuildConfig

class TokenManager(context: Context) {

    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val securePrefs: SharedPreferences = EncryptedSharedPreferences.create(
        context,
        "familienkalender_secure_prefs",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    private val prefs: SharedPreferences =
        context.getSharedPreferences("familienkalender_prefs", Context.MODE_PRIVATE)

    var token: String?
        get() = securePrefs.getString(KEY_TOKEN, null)
        set(value) = securePrefs.edit().putString(KEY_TOKEN, value).apply()

    var username: String?
        get() = prefs.getString(KEY_USERNAME, null)
        set(value) = prefs.edit().putString(KEY_USERNAME, value).apply()

    var userId: Int
        get() = prefs.getInt(KEY_USER_ID, -1)
        set(value) = prefs.edit().putInt(KEY_USER_ID, value).apply()

    var memberId: Int
        get() = prefs.getInt(KEY_MEMBER_ID, -1)
        set(value) = prefs.edit().putInt(KEY_MEMBER_ID, value).apply()

    var familyId: Int?
        get() {
            val v = prefs.getInt(KEY_FAMILY_ID, 0)
            return if (v == 0) null else v
        }
        set(value) = prefs.edit().putInt(KEY_FAMILY_ID, value ?: 0).apply()

    var serverUrl: String
        get() = prefs.getString(KEY_SERVER_URL, BuildConfig.DEFAULT_SERVER_URL)
            ?: BuildConfig.DEFAULT_SERVER_URL
        set(value) = prefs.edit().putString(KEY_SERVER_URL, value.trimEnd('/')).apply()

    val isLoggedIn: Boolean
        get() = token != null

    fun clear() {
        securePrefs.edit().clear().apply()
        prefs.edit()
            .remove(KEY_USERNAME)
            .remove(KEY_USER_ID)
            .remove(KEY_MEMBER_ID)
            .remove(KEY_FAMILY_ID)
            .apply()
    }

    companion object {
        private const val KEY_TOKEN = "jwt_token"
        private const val KEY_USERNAME = "username"
        private const val KEY_USER_ID = "user_id"
        private const val KEY_MEMBER_ID = "member_id"
        private const val KEY_FAMILY_ID = "family_id"
        private const val KEY_SERVER_URL = "server_url"
    }
}

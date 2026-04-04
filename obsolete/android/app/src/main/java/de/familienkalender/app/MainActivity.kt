package de.familienkalender.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.*
import androidx.lifecycle.viewmodel.compose.viewModel
import de.familienkalender.app.ui.auth.FamilyOnboardingScreen
import de.familienkalender.app.ui.auth.FamilyOnboardingViewModel
import de.familienkalender.app.ui.auth.LoginScreen
import de.familienkalender.app.ui.auth.LoginViewModel
import de.familienkalender.app.ui.navigation.AppNavigation
import de.familienkalender.app.ui.theme.FamilienkalenderTheme

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val app = application as FamilienkalenderApp

        setContent {
            FamilienkalenderTheme {
                val loginViewModel: LoginViewModel = viewModel(
                    factory = LoginViewModel.Factory(
                        app.authRepository, app.tokenManager, app.retrofitClient
                    )
                )
                val loginState by loginViewModel.uiState.collectAsState()

                if (!loginState.isLoggedIn) {
                    LoginScreen(viewModel = loginViewModel)
                } else if (!loginState.hasFamilyId) {
                    val onboardingVm: FamilyOnboardingViewModel = viewModel(
                        factory = FamilyOnboardingViewModel.Factory(app.authRepository)
                    )
                    val onboardingState by onboardingVm.uiState.collectAsState()

                    if (onboardingState.familyJoined) {
                        AppNavigation(
                            app = app,
                            onLogout = {
                                app.authRepository.logout()
                                recreate()
                            }
                        )
                    } else {
                        FamilyOnboardingScreen(viewModel = onboardingVm)
                    }
                } else {
                    AppNavigation(
                        app = app,
                        onLogout = {
                            app.authRepository.logout()
                            recreate()
                        }
                    )
                }
            }
        }
    }
}

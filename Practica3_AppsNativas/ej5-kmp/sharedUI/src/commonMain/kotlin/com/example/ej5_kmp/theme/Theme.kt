package com.example.ej5_kmp.theme

import androidx.compose.material3.ColorScheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.ui.graphics.Color

/**
 * Guinda (IPN) y Azul (ESCOM). Cada uno tiene una variante clara y una oscura; en
 * oscuro el color principal se aclara para que tenga contraste sobre fondo oscuro.
 */
enum class AppTheme(val label: String) {
    GUINDA("Guinda (IPN)"),
    AZUL("Azul (ESCOM)")
}

private val GuindaLight = Color(0xFF6C1D45)
private val GuindaLightContainer = Color(0xFFF5D9E6)
private val GuindaDark = Color(0xFFD98CB3)
private val GuindaOnDark = Color(0xFF3A0F26)

private val AzulLight = Color(0xFF0D2F5A)
private val AzulLightContainer = Color(0xFFD7E5F5)
private val AzulDark = Color(0xFF8FB4DE)
private val AzulOnDark = Color(0xFF062038)

fun colorSchemeFor(theme: AppTheme, isDark: Boolean): ColorScheme = when (theme) {
    AppTheme.GUINDA -> if (isDark) {
        darkColorScheme(
            primary = GuindaDark,
            onPrimary = GuindaOnDark,
            secondary = GuindaDark,
            primaryContainer = GuindaLight,
            onPrimaryContainer = GuindaDark
        )
    } else {
        lightColorScheme(
            primary = GuindaLight,
            onPrimary = Color.White,
            secondary = GuindaLight,
            primaryContainer = GuindaLightContainer,
            onPrimaryContainer = GuindaLight
        )
    }
    AppTheme.AZUL -> if (isDark) {
        darkColorScheme(
            primary = AzulDark,
            onPrimary = AzulOnDark,
            secondary = AzulDark,
            primaryContainer = AzulLight,
            onPrimaryContainer = AzulDark
        )
    } else {
        lightColorScheme(
            primary = AzulLight,
            onPrimary = Color.White,
            secondary = AzulLight,
            primaryContainer = AzulLightContainer,
            onPrimaryContainer = AzulLight
        )
    }
}

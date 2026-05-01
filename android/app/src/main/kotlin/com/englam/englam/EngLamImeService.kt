package com.ajmal.englam

import android.inputmethodservice.InputMethodService
import android.content.Context
import android.view.KeyEvent
import android.view.View

class EngLamImeService : InputMethodService(), EngLamKeyboardView.Listener {

    private var isMalayalamMode = true
    private var currentWord: String = ""
    private var suggestions: List<String> = emptyList()
    private var lastSpaceTapAt: Long = 0L
    private var keyboardHeightFactor: Float = 0.58f
    private var showKeyBorders: Boolean = false
    private var layoutMode: String = "translit"

    private lateinit var keyboardView: EngLamKeyboardView

    override fun onCreateInputView(): View {
        loadPrefs()
        keyboardView = EngLamKeyboardView(this).apply {
            setListener(this@EngLamImeService)
            setMalayalamMode(isMalayalamMode)
            setSuggestions(suggestions)
            setKeyboardHeightFactor(keyboardHeightFactor)
            setShowKeyBorders(showKeyBorders)
            setLayoutMode(layoutMode)
        }
        updateFromConnection()
        return keyboardView
    }

    override fun onStartInputView(info: android.view.inputmethod.EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        loadPrefs()
        if (this::keyboardView.isInitialized) {
            keyboardView.setKeyboardHeightFactor(keyboardHeightFactor)
            keyboardView.setShowKeyBorders(showKeyBorders)
            keyboardView.setLayoutMode(layoutMode)
            keyboardView.setMalayalamMode(isMalayalamMode)
        }
        updateFromConnection()
    }

    override fun onUpdateSelection(
        oldSelStart: Int,
        oldSelEnd: Int,
        newSelStart: Int,
        newSelEnd: Int,
        candidatesStart: Int,
        candidatesEnd: Int,
    ) {
        super.onUpdateSelection(oldSelStart, oldSelEnd, newSelStart, newSelEnd, candidatesStart, candidatesEnd)
        updateFromConnection()
    }

    override fun onInput(text: String) {
        val ic = currentInputConnection ?: return
        ic.commitText(text, 1)
        updateFromConnection()
    }

    override fun onDelete() {
        val ic = currentInputConnection ?: return
        ic.deleteSurroundingText(1, 0)
        updateFromConnection()
    }

    override fun onEnter() {
        val ic = currentInputConnection ?: return
        ic.sendKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_ENTER))
        ic.sendKeyEvent(KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_ENTER))
        updateFromConnection()
    }

    override fun onSpace() {
        val ic = currentInputConnection ?: return
        val now = System.currentTimeMillis()
        val isDoubleTap = now - lastSpaceTapAt < 300L
        lastSpaceTapAt = now

        val before = ic.getTextBeforeCursor(2, 0)?.toString() ?: ""
        if (isDoubleTap && before.endsWith(" ")) {
            ic.deleteSurroundingText(1, 0)
            ic.commitText(". ", 1)
            updateFromConnection()
            return
        }

        if (currentWord.trim().isEmpty()) {
            ic.commitText(" ", 1)
            updateFromConnection()
            return
        }

        if (!isMalayalamMode || layoutMode == "malayalam") {
            ic.commitText(" ", 1)
            updateFromConnection()
            return
        }

        val commit = suggestions.firstOrNull() ?: currentWord
        if (currentWord.isNotEmpty()) {
            ic.deleteSurroundingText(currentWord.length, 0)
            ic.commitText("$commit ", 1)
        } else {
            ic.commitText(" ", 1)
        }
        updateFromConnection()
    }

    override fun onToggleMalayalamMode() {
        isMalayalamMode = !isMalayalamMode
        savePrefs()
        keyboardView.setMalayalamMode(isMalayalamMode)
        updateFromConnection()
    }

    override fun onSuggestionSelect(word: String) {
        val ic = currentInputConnection ?: return
        if (layoutMode == "malayalam") return
        if (currentWord.isEmpty()) return
        ic.deleteSurroundingText(currentWord.length, 0)
        ic.commitText("$word ", 1)
        updateFromConnection()
    }

    override fun onSymbolsToggle(isSymbols: Boolean) {
        lastSpaceTapAt = 0L
    }

    override fun onToggleLayoutMode() {
        layoutMode =
            when (layoutMode) {
                "translit" -> "malayalam"
                "malayalam" -> "handwriting"
                else -> "translit"
            }
        if (layoutMode == "handwriting") {
            isMalayalamMode = true
        }
        savePrefs()
        keyboardView.setLayoutMode(layoutMode)
        updateFromConnection()
    }

    private fun updateFromConnection() {
        val ic = currentInputConnection ?: return
        val before = ic.getTextBeforeCursor(200, 0)?.toString() ?: ""
        val word = before.takeLastWhile { !it.isWhitespace() }
        currentWord = word
        suggestions =
            if (layoutMode == "malayalam" || layoutMode == "handwriting") {
                emptyList()
            } else {
                SuggestionEngine.getSuggestions(currentWord, isMalayalamMode)
            }
        if (this::keyboardView.isInitialized) {
            if (layoutMode != "handwriting") {
                keyboardView.setSuggestions(suggestions)
            }
            keyboardView.setMalayalamMode(isMalayalamMode)
        }
    }

    private fun loadPrefs() {
        val prefs = getSharedPreferences("englam_prefs", Context.MODE_PRIVATE)
        keyboardHeightFactor = prefs.getFloat("keyboardHeightFactor", 0.58f).coerceIn(0.45f, 0.75f)
        showKeyBorders = prefs.getBoolean("showKeyBorders", false)
        layoutMode = prefs.getString("layoutMode", "translit") ?: "translit"
        isMalayalamMode = prefs.getBoolean("isMalayalamMode", true)
    }

    private fun savePrefs() {
        val prefs = getSharedPreferences("englam_prefs", Context.MODE_PRIVATE)
        prefs.edit().putString("layoutMode", layoutMode).putBoolean("isMalayalamMode", isMalayalamMode).apply()
    }
}

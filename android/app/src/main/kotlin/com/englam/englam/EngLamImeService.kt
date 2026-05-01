package com.englam.englam

import android.inputmethodservice.InputMethodService
import android.view.KeyEvent
import android.view.View

class EngLamImeService : InputMethodService(), EngLamKeyboardView.Listener {

    private var isMalayalamMode = true
    private var currentWord: String = ""
    private var suggestions: List<String> = emptyList()
    private var lastSpaceTapAt: Long = 0L

    private lateinit var keyboardView: EngLamKeyboardView

    override fun onCreateInputView(): View {
        keyboardView = EngLamKeyboardView(this).apply {
            setListener(this@EngLamImeService)
            setMalayalamMode(isMalayalamMode)
            setSuggestions(suggestions)
        }
        updateFromConnection()
        return keyboardView
    }

    override fun onStartInputView(info: android.view.inputmethod.EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
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

        if (!isMalayalamMode) {
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
        keyboardView.setMalayalamMode(isMalayalamMode)
        updateFromConnection()
    }

    override fun onSuggestionSelect(word: String) {
        val ic = currentInputConnection ?: return
        if (currentWord.isEmpty()) return
        ic.deleteSurroundingText(currentWord.length, 0)
        ic.commitText("$word ", 1)
        updateFromConnection()
    }

    override fun onSymbolsToggle(isSymbols: Boolean) {
        lastSpaceTapAt = 0L
    }

    private fun updateFromConnection() {
        val ic = currentInputConnection ?: return
        val before = ic.getTextBeforeCursor(200, 0)?.toString() ?: ""
        val word = before.takeLastWhile { !it.isWhitespace() }
        currentWord = word
        suggestions = SuggestionEngine.getSuggestions(currentWord, isMalayalamMode)
        if (this::keyboardView.isInitialized) {
            keyboardView.setSuggestions(suggestions)
            keyboardView.setMalayalamMode(isMalayalamMode)
        }
    }
}


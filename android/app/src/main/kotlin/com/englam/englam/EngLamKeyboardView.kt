package com.ajmal.englam

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.util.AttributeSet
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.widget.HorizontalScrollView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import kotlin.math.roundToInt

class EngLamKeyboardView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
) : LinearLayout(context, attrs) {

    interface Listener {
        fun onInput(text: String)
        fun onDelete()
        fun onEnter()
        fun onSpace()
        fun onToggleMalayalamMode()
        fun onToggleLayoutMode()
        fun onSuggestionSelect(word: String)
        fun onSymbolsToggle(isSymbols: Boolean)
    }

    private val handler = Handler(Looper.getMainLooper())
    private var listener: Listener? = null

    private val suggestionRow = LinearLayout(context).apply {
        orientation = HORIZONTAL
        layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, 44.dp())
        setBackgroundColor(Color.parseColor("#1D1F2D"))
        gravity = Gravity.CENTER_VERTICAL
    }

    private val modeBox = TextView(context).apply {
        layoutParams = LayoutParams(44.dp(), LayoutParams.MATCH_PARENT)
        gravity = Gravity.CENTER
        textSize = 11f
        setTypeface(typeface, Typeface.BOLD)
        setTextColor(Color.parseColor("#7C5CFF"))
    }

    private val suggestionsScroll = HorizontalScrollView(context).apply {
        layoutParams = LayoutParams(0, LayoutParams.MATCH_PARENT, 1f)
        isHorizontalScrollBarEnabled = false
        overScrollMode = View.OVER_SCROLL_NEVER
    }

    private val suggestionsContainer = LinearLayout(context).apply {
        orientation = HORIZONTAL
        layoutParams = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.MATCH_PARENT)
        gravity = Gravity.CENTER_VERTICAL
    }

    private val keyAreaScroll = ScrollView(context).apply {
        layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        isVerticalScrollBarEnabled = false
        overScrollMode = View.OVER_SCROLL_NEVER
    }

    private val keyArea = LinearLayout(context).apply {
        orientation = VERTICAL
        layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        setPadding(8.dp(), 8.dp(), 8.dp(), 10.dp())
    }

    private val suggestionRowHeightPx = 44.dp()
    private val rowSpacerPx = 8.dp()
    private var keyboardHeightPx: Int? = null
    private var keyHeightPx: Int = 46.dp()

    private val malayalamLayout = listOf(
        listOf("അ", "ആ", "ഇ", "ഈ", "ഉ", "ഊ", "എ", "ഏ", "ഒ", "ഓ"),
        listOf("ക", "ഖ", "ഗ", "ഘ", "ങ", "ച", "ഛ", "ജ", "ഝ", "ഞ"),
        listOf("ട", "ഠ", "ഡ", "ഢ", "ണ", "ത", "ഥ", "ദ", "ധ", "ന"),
        listOf("പ", "ഫ", "ബ", "ഭ", "മ", "യ", "ര", "ല", "വ", "സ"),
    )

    private val numbersRow = listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "0")

    private val alphaLayout = listOf(
        listOf("q", "w", "e", "r", "t", "y", "u", "i", "o", "p"),
        listOf("a", "s", "d", "f", "g", "h", "j", "k", "l"),
        listOf("z", "x", "c", "v", "b", "n", "m"),
    )

    private val symbolsRow2 = listOf("@", "#", "₹", "_", "&", "-", "+", "(", ")", "/")
    private val symbolsRow3 = listOf("*", "\"", "'", ":", ";", "!", "?", "…")
    private val symbolsRow4A = listOf("%", "=", "/", "\\", "|")
    private val symbolsRow4B = listOf("[", "]", "{", "}", "<", ">", "~")

    private var isShift = false
    private var isCaps = false
    private var isSymbols = false
    private var isMoreSymbols = false
    private var isMalayalamMode = true
    private var showKeyBorders = false
    private var layoutMode: String = "translit"

    private var suggestions: List<String> = emptyList()
    private var handwritingCandidates: List<String> = emptyList()

    private val handwritingRecognizer = HandwritingRecognizer(context)
    private val handwritingPad = HandwritingPadView(context).apply {
        setListener(
            object : HandwritingPadView.Listener {
                override fun onStrokeEnd() {
                    handler.removeCallbacks(handwritingDebounce)
                    handler.postDelayed(handwritingDebounce, 320L)
                }
            },
        )
    }

    private val handwritingDebounce = Runnable {
        recognizeHandwriting()
    }

    private val deleteRepeater = object : Runnable {
        override fun run() {
            listener?.onDelete()
            handler.postDelayed(this, 55L)
        }
    }

    private var deleteDelayPosted = false

    init {
        orientation = VERTICAL
        setBackgroundColor(Color.parseColor("#171826"))
        elevation = 24.dp().toFloat()

        suggestionsScroll.addView(suggestionsContainer)

        suggestionRow.addView(makeIconBox("‹"))
        suggestionRow.addView(modeBox)
        suggestionRow.addView(suggestionsScroll)
        suggestionRow.addView(makeIconBox("🎤"))

        addView(suggestionRow)

        keyAreaScroll.addView(keyArea)
        addView(keyAreaScroll)

        rebuildKeys()
        setSuggestions(emptyList())
        setMalayalamMode(true)
    }

    fun setListener(l: Listener) {
        listener = l
    }

    fun setMalayalamMode(isMalayalam: Boolean) {
        isMalayalamMode = isMalayalam
        modeBox.text = if (isMalayalam) "MA" else "EN"
        modeBox.setTextColor(if (isMalayalam) Color.parseColor("#7C5CFF") else Color.parseColor("#8B92A8"))
        rebuildKeys()
    }

    fun setLayoutMode(mode: String) {
        layoutMode = mode
        rebuildKeys()
    }

    fun setShowKeyBorders(show: Boolean) {
        showKeyBorders = show
        rebuildKeys()
    }

    fun setKeyboardHeightFactor(factor: Float) {
        val v = factor.coerceIn(0.45f, 0.75f)
        post {
            val h = (resources.displayMetrics.heightPixels * v).toInt()
            keyboardHeightPx = h
            val lp = layoutParams ?: LayoutParams(LayoutParams.MATCH_PARENT, h)
            lp.height = h
            layoutParams = lp
            requestLayout()
            rebuildKeys()
        }
    }

    fun setSuggestions(items: List<String>) {
        suggestions = items
        suggestionsContainer.removeAllViews()
        if (items.isEmpty()) {
            suggestionsContainer.addView(
                TextView(context).apply {
                    layoutParams = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.MATCH_PARENT).apply {
                        leftMargin = 16.dp()
                        rightMargin = 16.dp()
                    }
                    gravity = Gravity.CENTER_VERTICAL
                    text = "EngLam"
                    setTextColor(Color.parseColor("#777777"))
                    setTypeface(typeface, Typeface.BOLD)
                },
            )
            return
        }
        items.take(10).forEachIndexed { index, s ->
            val chip = TextView(context).apply {
                layoutParams = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.MATCH_PARENT)
                setPadding(16.dp(), 0, 16.dp(), 0)
                gravity = Gravity.CENTER
                text = s
                textSize = 15f
                setTypeface(typeface, Typeface.BOLD)
                setTextColor(Color.parseColor("#7C5CFF"))
                setOnClickListener { listener?.onSuggestionSelect(s) }
            }
            suggestionsContainer.addView(chip)
            if (index != items.size - 1) {
                suggestionsContainer.addView(divider())
            }
        }
    }

    private fun rebuildKeys() {
        val rows = if (layoutMode == "malayalam") malayalamLayout else alphaLayout
        keyArea.removeAllViews()
        keyHeightPx = computeKeyHeightPx()

        if (!isSymbols && layoutMode == "handwriting") {
            setHandwritingCandidates(emptyList())
            keyArea.addView(buildHandwritingPad())
            keyArea.addView(spacer8())
            keyArea.addView(buildHandwritingBottomRow())
            return
        }

        if (isSymbols) {
            keyArea.addView(buildKeyRow(numbersRow, labelTransform = null))
            keyArea.addView(spacer8())
            keyArea.addView(buildKeyRow(symbolsRow2, labelTransform = null))
            keyArea.addView(spacer8())
            keyArea.addView(buildKeyRow(symbolsRow3, widthFactor = 0.9f, labelTransform = null))
            keyArea.addView(spacer8())
            keyArea.addView(buildShiftDeleteRow())
            keyArea.addView(spacer8())
            keyArea.addView(buildBottomRow())
            return
        }

        keyArea.addView(buildKeyRow(rows[0], labelTransform = null))
        keyArea.addView(spacer8())
        keyArea.addView(buildKeyRow(rows[1], widthFactor = 0.9f))
        if (layoutMode == "malayalam") {
            keyArea.addView(spacer8())
            keyArea.addView(buildKeyRow(rows[2], widthFactor = 0.9f))
        }
        keyArea.addView(spacer8())
        keyArea.addView(buildShiftDeleteRow())
        keyArea.addView(spacer8())
        keyArea.addView(buildBottomRow())
    }

    private fun buildKeyRow(keys: List<String>, widthFactor: Float? = null, labelTransform: ((String) -> String)? = null): View {
        val row = LinearLayout(context).apply {
            orientation = HORIZONTAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
            gravity = Gravity.CENTER_HORIZONTAL
        }

        val inner = LinearLayout(context).apply {
            orientation = HORIZONTAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        }

        keys.forEachIndexed { i, k ->
            val label = labelTransform?.invoke(k) ?: transformLabel(k)
            val key = makeKey(label) { handleKey(k) }
            inner.addView(key, LayoutParams(0, keyHeightPx, 1f))
            if (i != keys.lastIndex) inner.addView(space6())
        }

        if (widthFactor == null) {
            row.addView(inner)
            return row
        }

        row.addView(
            inner,
            LayoutParams(0, LayoutParams.WRAP_CONTENT, widthFactor).apply { gravity = Gravity.CENTER_HORIZONTAL },
        )
        row.addView(View(context), LayoutParams(0, 0, 1f - widthFactor))
        return row
    }

    private fun buildShiftDeleteRow(): View {
        val row = LinearLayout(context).apply {
            orientation = HORIZONTAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        }

        val shiftLabel = if (isSymbols) "=<" else "↑"
        val shift = makeActionKey(shiftLabel, isActive = isShift || isCaps, minWidthDp = 54) {
            if (isSymbols) {
                isMoreSymbols = !isMoreSymbols
            } else {
                if (isShift) {
                    isCaps = true
                    isShift = false
                } else if (isCaps) {
                    isCaps = false
                    isShift = false
                } else {
                    isShift = true
                }
            }
            rebuildKeys()
        }

        row.addView(shift, LayoutParams(LayoutParams.WRAP_CONTENT, keyHeightPx))
        row.addView(space6())

        val rows = if (layoutMode == "malayalam") malayalamLayout else alphaLayout
        val middle = buildKeyRow(
            if (isSymbols) {
                if (isMoreSymbols) symbolsRow4B else symbolsRow4A
            } else {
                if (layoutMode == "malayalam") rows[3] else rows[2]
            },
        )
        row.addView(middle, LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f))
        row.addView(space6())

        val del = makeActionKey("⌫", disablePopup = true, minWidthDp = 54, onTap = { listener?.onDelete() })
        del.setOnTouchListener { _, event ->
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    startDeleteHold()
                    true
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    stopDeleteHold()
                    false
                }
                else -> false
            }
        }

        row.addView(del, LayoutParams(LayoutParams.WRAP_CONTENT, keyHeightPx))
        return row
    }

    private fun buildBottomRow(): View {
        val row = LinearLayout(context).apply {
            orientation = HORIZONTAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        }

        val toggle = makeActionKey(if (isSymbols) "ABC" else "?123", disablePopup = true, minWidthDp = 72) {
            isSymbols = !isSymbols
            if (!isSymbols) isMoreSymbols = false
            isShift = false
            isCaps = false
            listener?.onSymbolsToggle(isSymbols)
            rebuildKeys()
        }

        val comma = makeActionKey(",", minWidthDp = 44) { handleKey(",") }

        val layoutToggleLabel = when (layoutMode) {
            "translit" -> "അ"
            "malayalam" -> "✍"
            else -> "abc"
        }
        val layoutToggle = makeActionKey(layoutToggleLabel, disablePopup = true, minWidthDp = 52) {
            isSymbols = false
            isMoreSymbols = false
            isShift = false
            isCaps = false
            listener?.onToggleLayoutMode()
        }

        val lang = makeActionKey("ma", isPrimary = isMalayalamMode, isAction = !isMalayalamMode, disablePopup = true, minWidthDp = 44) {
            listener?.onToggleMalayalamMode()
        }

        val space = makeKey("", bg = Color.parseColor("#2A2D3A"), disablePopup = true, minWidthDp = 0) {
            listener?.onSpace()
        }.apply {
            addView(
                View(context).apply {
                    setBackgroundColor(Color.parseColor("#3A3F55"))
                },
                LayoutParams(90.dp(), 4.dp()).apply {
                    gravity = Gravity.CENTER
                },
            )
        }

        val dot = makeActionKey(".", minWidthDp = 44) { handleKey(".") }
        val enter = makePrimaryKey("⏎", disablePopup = true, minWidthDp = 72) { listener?.onEnter() }

        row.addView(toggle, LayoutParams(LayoutParams.WRAP_CONTENT, keyHeightPx))
        row.addView(space6())
        row.addView(comma, LayoutParams(LayoutParams.WRAP_CONTENT, keyHeightPx))
        row.addView(space6())
        row.addView(layoutToggle, LayoutParams(LayoutParams.WRAP_CONTENT, keyHeightPx))
        row.addView(space6())
        row.addView(lang, LayoutParams(LayoutParams.WRAP_CONTENT, keyHeightPx))
        row.addView(space6())
        row.addView(space, LayoutParams(0, keyHeightPx, 1f))
        row.addView(space6())
        row.addView(dot, LayoutParams(LayoutParams.WRAP_CONTENT, keyHeightPx))
        row.addView(space6())
        row.addView(enter, LayoutParams(LayoutParams.WRAP_CONTENT, keyHeightPx))
        return row
    }

    private fun handleKey(raw: String) {
        if (isSymbols) {
            listener?.onInput(raw)
            return
        }
        var out = raw
        if (isShift || isCaps) out = out.uppercase()
        listener?.onInput(out)
        if (isShift && !isCaps) {
            isShift = false
            rebuildKeys()
        }
    }

    private fun transformLabel(k: String): String {
        if (isSymbols) return k
        return if (isShift || isCaps) k.uppercase() else k
    }

    private fun startDeleteHold() {
        stopDeleteHold()
        deleteDelayPosted = true
        handler.postDelayed(
            {
                if (!deleteDelayPosted) return@postDelayed
                handler.post(deleteRepeater)
            },
            320L,
        )
    }

    private fun stopDeleteHold() {
        deleteDelayPosted = false
        handler.removeCallbacks(deleteRepeater)
    }

    private fun makeIconBox(label: String): View {
        return TextView(context).apply {
            layoutParams = LayoutParams(44.dp(), LayoutParams.MATCH_PARENT)
            gravity = Gravity.CENTER
            text = label
            textSize = 16f
            setTextColor(Color.parseColor("#8B92A8"))
        }
    }

    private fun divider(): View {
        return View(context).apply {
            layoutParams = LayoutParams(1.dp(), LayoutParams.MATCH_PARENT)
            setBackgroundColor(Color.parseColor("#2B2F44"))
        }
    }

    private fun spacer8(): View = View(context).apply { layoutParams = LayoutParams(0, rowSpacerPx) }

    private fun space6(): View = View(context).apply { layoutParams = LayoutParams(6.dp(), 0) }

    private fun buildHandwritingPad(): View {
        val root = LinearLayout(context).apply {
            orientation = VERTICAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        }

        val bg = GradientDrawable()
        bg.shape = GradientDrawable.RECTANGLE
        bg.cornerRadius = 12.dp().toFloat()
        bg.setColor(Color.parseColor("#0E1017"))
        bg.setStroke(1.dp(), Color.parseColor("#2B2F44"))
        root.background = bg
        root.setPadding(10.dp(), 10.dp(), 10.dp(), 10.dp())

        root.addView(handwritingPad, LayoutParams(LayoutParams.MATCH_PARENT, 172.dp()))
        return root
    }

    private fun buildHandwritingBottomRow(): View {
        val row = LinearLayout(context).apply {
            orientation = HORIZONTAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        }

        val toggle = makeActionKey(if (isSymbols) "ABC" else "?123", disablePopup = true, minWidthDp = 72) {
            isSymbols = !isSymbols
            if (!isSymbols) isMoreSymbols = false
            isShift = false
            isCaps = false
            listener?.onSymbolsToggle(isSymbols)
            rebuildKeys()
        }

        val del = makeActionKey("⌫", disablePopup = true, minWidthDp = 54) {
            if (handwritingPad.hasInk()) {
                handler.removeCallbacks(handwritingDebounce)
                handwritingPad.clearInk()
                setHandwritingCandidates(emptyList())
            } else {
                listener?.onDelete()
            }
        }

        val clear = makeActionKey("CLR", disablePopup = true, minWidthDp = 62) {
            handler.removeCallbacks(handwritingDebounce)
            handwritingPad.clearInk()
            setHandwritingCandidates(emptyList())
        }

        val layoutToggleLabel = when (layoutMode) {
            "translit" -> "അ"
            "malayalam" -> "✍"
            else -> "abc"
        }
        val layoutToggle = makeActionKey(layoutToggleLabel, disablePopup = true, minWidthDp = 52) {
            isSymbols = false
            isMoreSymbols = false
            isShift = false
            isCaps = false
            listener?.onToggleLayoutMode()
        }

        val space = makeKey("", bg = Color.parseColor("#2A2D3A"), disablePopup = true, minWidthDp = 0) {
            if (handwritingPad.hasInk() && handwritingCandidates.isNotEmpty()) {
                listener?.onInput(handwritingCandidates.first())
                handler.removeCallbacks(handwritingDebounce)
                handwritingPad.clearInk()
                setHandwritingCandidates(emptyList())
            }
            listener?.onSpace()
        }.apply {
            addView(
                View(context).apply { setBackgroundColor(Color.parseColor("#3A3F55")) },
                LayoutParams(90.dp(), 4.dp()).apply { gravity = Gravity.CENTER },
            )
        }

        val dot = makeActionKey(".", minWidthDp = 44) { listener?.onInput(".") }
        val enter = makePrimaryKey("⏎", disablePopup = true, minWidthDp = 72) {
            if (handwritingPad.hasInk() && handwritingCandidates.isNotEmpty()) {
                listener?.onInput(handwritingCandidates.first())
                handler.removeCallbacks(handwritingDebounce)
                handwritingPad.clearInk()
                setHandwritingCandidates(emptyList())
                return@makePrimaryKey
            }
            listener?.onEnter()
        }

        row.addView(toggle, LayoutParams(LayoutParams.WRAP_CONTENT, keyHeightPx))
        row.addView(space6())
        row.addView(del, LayoutParams(LayoutParams.WRAP_CONTENT, keyHeightPx))
        row.addView(space6())
        row.addView(clear, LayoutParams(LayoutParams.WRAP_CONTENT, keyHeightPx))
        row.addView(space6())
        row.addView(layoutToggle, LayoutParams(LayoutParams.WRAP_CONTENT, keyHeightPx))
        row.addView(space6())
        row.addView(space, LayoutParams(0, keyHeightPx, 1f))
        row.addView(space6())
        row.addView(dot, LayoutParams(LayoutParams.WRAP_CONTENT, keyHeightPx))
        row.addView(space6())
        row.addView(enter, LayoutParams(LayoutParams.WRAP_CONTENT, keyHeightPx))
        return row
    }

    private fun recognizeHandwriting() {
        if (layoutMode != "handwriting" || isSymbols) return
        if (!handwritingPad.hasInk()) {
            setHandwritingCandidates(emptyList())
            return
        }
        val ink = handwritingPad.buildInk()
        handwritingRecognizer.recognize(
            ink,
            onResult = { out ->
                setHandwritingCandidates(out)
            },
            onError = {
                setHandwritingCandidates(emptyList())
            },
        )
    }

    private fun setHandwritingCandidates(items: List<String>) {
        handwritingCandidates = items
        suggestionsContainer.removeAllViews()
        if (items.isEmpty()) {
            suggestionsContainer.addView(
                TextView(context).apply {
                    layoutParams = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.MATCH_PARENT).apply {
                        leftMargin = 16.dp()
                        rightMargin = 16.dp()
                    }
                    gravity = Gravity.CENTER_VERTICAL
                    text = "Write…"
                    setTextColor(Color.parseColor("#777777"))
                    setTypeface(typeface, Typeface.BOLD)
                },
            )
            return
        }
        items.take(10).forEachIndexed { index, s ->
            val chip = TextView(context).apply {
                layoutParams = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.MATCH_PARENT)
                setPadding(16.dp(), 0, 16.dp(), 0)
                gravity = Gravity.CENTER
                text = s
                textSize = 15f
                setTypeface(typeface, Typeface.BOLD)
                setTextColor(Color.parseColor("#7C5CFF"))
                setOnClickListener {
                    listener?.onInput(s)
                    handler.removeCallbacks(handwritingDebounce)
                    handwritingPad.clearInk()
                    setHandwritingCandidates(emptyList())
                }
            }
            suggestionsContainer.addView(chip)
            if (index != items.size - 1) {
                suggestionsContainer.addView(divider())
            }
        }
    }

    private fun makeKey(
        label: String,
        bg: Int = Color.parseColor("#2A2D3A"),
        disablePopup: Boolean = false,
        minWidthDp: Int = 0,
        onTap: (() -> Unit)?,
    ): LinearLayout {
        val root = LinearLayout(context).apply {
            orientation = VERTICAL
            gravity = Gravity.CENTER
            minimumWidth = minWidthDp.dp()
            setPadding(0, 0, 0, 0)
        }

        val tv = TextView(context).apply {
            text = label
            gravity = Gravity.CENTER
            textSize = 19f
            setTypeface(typeface, Typeface.BOLD)
            setTextColor(Color.WHITE)
        }

        if (label.isNotEmpty()) root.addView(tv, LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT))

        var pressed = false
        val pressedColor = Color.parseColor("#3A3F55")
        fun applyBg(v: View, color: Int) {
            val d = GradientDrawable()
            d.shape = GradientDrawable.RECTANGLE
            d.cornerRadius = 10.dp().toFloat()
            d.setColor(color)
            if (showKeyBorders) d.setStroke(1.dp(), Color.parseColor("#2B2F44"))
            v.background = d
        }
        applyBg(root, bg)

        root.setOnTouchListener { v, event ->
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    pressed = true
                    applyBg(v, pressedColor)
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (pressed) {
                        applyBg(v, bg)
                        pressed = false
                        onTap?.invoke()
                    }
                    true
                }
                MotionEvent.ACTION_CANCEL -> {
                    applyBg(v, bg)
                    pressed = false
                    true
                }
                else -> false
            }
        }

        if (!disablePopup && label.isNotEmpty()) {
            root.setOnLongClickListener {
                false
            }
        }

        return root
    }

    private fun makeActionKey(
        label: String,
        isPrimary: Boolean = false,
        isAction: Boolean = true,
        isActive: Boolean = false,
        disablePopup: Boolean = false,
        minWidthDp: Int = 0,
        onTap: (() -> Unit)?,
    ): LinearLayout {
        val bg = when {
            isPrimary -> Color.parseColor("#7C5CFF")
            isAction -> Color.parseColor("#202334")
            else -> Color.parseColor("#2A2D3A")
        }
        val fg = if (isPrimary) Color.BLACK else Color.WHITE
        val root = makeKey(label, bg = if (isActive) Color.parseColor("#3A3F55") else bg, disablePopup = disablePopup, minWidthDp = minWidthDp, onTap = onTap)
        if (label.isNotEmpty()) (root.getChildAt(0) as? TextView)?.setTextColor(fg)
        return root
    }

    private fun makePrimaryKey(
        label: String,
        disablePopup: Boolean = false,
        minWidthDp: Int = 0,
        onTap: (() -> Unit)?,
    ): LinearLayout {
        return makeActionKey(label, isPrimary = true, isAction = false, disablePopup = disablePopup, minWidthDp = minWidthDp, onTap = onTap)
    }

    private fun Int.dp(): Int = (this * resources.displayMetrics.density).roundToInt()

    private fun computeKeyHeightPx(): Int {
        val target = keyboardHeightPx ?: return 46.dp()
        val keyRows = when {
            isSymbols -> 5
            layoutMode == "malayalam" -> 5
            layoutMode == "handwriting" -> 3
            else -> 4
        }
        val spacerCount = keyRows - 1
        val paddingV = keyArea.paddingTop + keyArea.paddingBottom
        val available = target - suggestionRowHeightPx - paddingV - (rowSpacerPx * spacerCount)
        if (available <= 0) return 46.dp()
        val raw = available / keyRows
        val min = 40.dp()
        val max = 96.dp()
        return raw.coerceIn(min, max)
    }
}

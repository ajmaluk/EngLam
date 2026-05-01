package com.englam.englam

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
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
        fun onSuggestionSelect(word: String)
        fun onSymbolsToggle(isSymbols: Boolean)
    }

    private val handler = Handler(Looper.getMainLooper())
    private var listener: Listener? = null

    private val suggestionRow = LinearLayout(context).apply {
        orientation = HORIZONTAL
        layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, 44.dp())
        setBackgroundColor(Color.parseColor("#202020"))
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

    private val alphaLayout = listOf(
        listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "0"),
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

    private var suggestions: List<String> = emptyList()

    private val deleteRepeater = object : Runnable {
        override fun run() {
            listener?.onDelete()
            handler.postDelayed(this, 55L)
        }
    }

    private var deleteDelayPosted = false

    init {
        orientation = VERTICAL
        setBackgroundColor(Color.parseColor("#1A1A1A"))
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
        modeBox.text = if (isMalayalam) "ML" else "EN"
        modeBox.setTextColor(if (isMalayalam) Color.parseColor("#7C5CFF") else Color.parseColor("#8B92A8"))
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
        keyArea.removeAllViews()
        keyArea.addView(buildKeyRow(alphaLayout[0], labelTransform = null))
        keyArea.addView(spacer8())
        keyArea.addView(buildKeyRow(if (isSymbols) symbolsRow2 else alphaLayout[1]))
        keyArea.addView(spacer8())
        keyArea.addView(buildKeyRow(if (isSymbols) symbolsRow3 else alphaLayout[2], widthFactor = 0.9f))
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
            inner.addView(key, LayoutParams(0, 46.dp(), 1f))
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

        row.addView(shift, LayoutParams(LayoutParams.WRAP_CONTENT, 46.dp()))
        row.addView(space6())

        val middle = buildKeyRow(if (isSymbols) (if (isMoreSymbols) symbolsRow4B else symbolsRow4A) else alphaLayout[3])
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

        row.addView(del, LayoutParams(LayoutParams.WRAP_CONTENT, 46.dp()))
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

        val lang = makeActionKey("മ", isPrimary = isMalayalamMode, isAction = !isMalayalamMode, disablePopup = true, minWidthDp = 44) {
            listener?.onToggleMalayalamMode()
        }

        val space = makeKey("", bg = Color.parseColor("#404040"), disablePopup = true, minWidthDp = 0) {
            listener?.onSpace()
        }.apply {
            addView(
                View(context).apply {
                    setBackgroundColor(Color.parseColor("#555555"))
                },
                LayoutParams(90.dp(), 4.dp()).apply {
                    gravity = Gravity.CENTER
                },
            )
        }

        val dot = makeActionKey(".", minWidthDp = 44) { handleKey(".") }
        val enter = makePrimaryKey("⏎", disablePopup = true, minWidthDp = 72) { listener?.onEnter() }

        row.addView(toggle, LayoutParams(LayoutParams.WRAP_CONTENT, 46.dp()))
        row.addView(space6())
        row.addView(comma, LayoutParams(LayoutParams.WRAP_CONTENT, 46.dp()))
        row.addView(space6())
        row.addView(lang, LayoutParams(LayoutParams.WRAP_CONTENT, 46.dp()))
        row.addView(space6())
        row.addView(space, LayoutParams(0, 46.dp(), 1f))
        row.addView(space6())
        row.addView(dot, LayoutParams(LayoutParams.WRAP_CONTENT, 46.dp()))
        row.addView(space6())
        row.addView(enter, LayoutParams(LayoutParams.WRAP_CONTENT, 46.dp()))
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
            setTextColor(Color.parseColor("#B0B0B0"))
        }
    }

    private fun divider(): View {
        return View(context).apply {
            layoutParams = LayoutParams(1.dp(), LayoutParams.MATCH_PARENT)
            setBackgroundColor(Color.parseColor("#303030"))
        }
    }

    private fun spacer8(): View = View(context).apply { layoutParams = LayoutParams(0, 8.dp()) }

    private fun space6(): View = View(context).apply { layoutParams = LayoutParams(6.dp(), 0) }

    private fun makeKey(
        label: String,
        bg: Int = Color.parseColor("#404040"),
        disablePopup: Boolean = false,
        minWidthDp: Int = 0,
        onTap: (() -> Unit)?,
    ): LinearLayout {
        val root = LinearLayout(context).apply {
            orientation = VERTICAL
            gravity = Gravity.CENTER
            minimumWidth = minWidthDp.dp()
            setPadding(0, 0, 0, 0)
            setBackgroundColor(bg)
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
        val pressedColor = Color.parseColor("#555555")
        root.setOnTouchListener { v, event ->
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    pressed = true
                    v.setBackgroundColor(pressedColor)
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (pressed) {
                        v.setBackgroundColor(bg)
                        pressed = false
                        onTap?.invoke()
                    }
                    true
                }
                MotionEvent.ACTION_CANCEL -> {
                    v.setBackgroundColor(bg)
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
            isAction -> Color.parseColor("#313131")
            else -> Color.parseColor("#404040")
        }
        val fg = if (isPrimary) Color.BLACK else Color.WHITE
        val root = makeKey(label, bg = if (isActive) Color.parseColor("#555555") else bg, disablePopup = disablePopup, minWidthDp = minWidthDp, onTap = onTap)
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
}

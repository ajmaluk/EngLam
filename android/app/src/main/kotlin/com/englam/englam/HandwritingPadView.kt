package com.ajmal.englam

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.View
import com.google.mlkit.vision.digitalink.recognition.Ink

class HandwritingPadView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
) : View(context, attrs) {

    interface Listener {
        fun onStrokeEnd()
    }

    private var listener: Listener? = null
    private val strokes: MutableList<MutableList<Ink.Point>> = mutableListOf()
    private var active: MutableList<Ink.Point>? = null

    private val paint = Paint().apply {
        color = Color.WHITE
        style = Paint.Style.STROKE
        strokeWidth = 8f
        strokeCap = Paint.Cap.ROUND
        strokeJoin = Paint.Join.ROUND
        isAntiAlias = true
    }

    fun setListener(l: Listener?) {
        listener = l
    }

    fun clearInk() {
        strokes.clear()
        active = null
        invalidate()
        listener?.onStrokeEnd()
    }

    fun hasInk(): Boolean = strokes.isNotEmpty() || (active?.isNotEmpty() == true)

    fun buildInk(): Ink {
        val ink = Ink.builder()
        for (s in strokes) {
            if (s.isEmpty()) continue
            val b = Ink.Stroke.builder()
            for (p in s) b.addPoint(p)
            ink.addStroke(b.build())
        }
        return ink.build()
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        val x = event.x.coerceIn(0f, width.toFloat())
        val y = event.y.coerceIn(0f, height.toFloat())
        val t = event.eventTime
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                parent.requestDisallowInterceptTouchEvent(true)
                active = mutableListOf(Ink.Point.create(x, y, t))
                invalidate()
                return true
            }
            MotionEvent.ACTION_MOVE -> {
                val a = active ?: return true
                for (i in 0 until event.historySize) {
                    val hx = event.getHistoricalX(i).coerceIn(0f, width.toFloat())
                    val hy = event.getHistoricalY(i).coerceIn(0f, height.toFloat())
                    val ht = event.getHistoricalEventTime(i)
                    a.add(Ink.Point.create(hx, hy, ht))
                }
                a.add(Ink.Point.create(x, y, t))
                invalidate()
                return true
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                val a = active
                if (a != null && a.isNotEmpty()) {
                    strokes.add(a)
                }
                active = null
                invalidate()
                listener?.onStrokeEnd()
                parent.requestDisallowInterceptTouchEvent(false)
                return true
            }
        }
        return super.onTouchEvent(event)
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        fun drawStroke(points: List<Ink.Point>) {
            if (points.isEmpty()) return
            if (points.size == 1) {
                canvas.drawCircle(points[0].x, points[0].y, 2f, paint)
                return
            }
            val path = Path()
            path.moveTo(points[0].x, points[0].y)
            for (i in 1 until points.size) {
                path.lineTo(points[i].x, points[i].y)
            }
            canvas.drawPath(path, paint)
        }
        for (s in strokes) drawStroke(s)
        active?.let { drawStroke(it) }
    }
}

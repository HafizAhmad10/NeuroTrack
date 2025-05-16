package com.example.neurotrack

import android.content.Context
import android.graphics.Bitmap
import org.tensorflow.lite.Interpreter
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.FileChannel

class TFLiteHelper(context: Context) {
    private val interpreter: Interpreter

    init {
        val assetManager = context.assets
        val inputStream = assetManager.open("models/spiral_model01.tflite")
        val fileDescriptor = assetManager.openFd("models/spiral_model01.tflite")

        val fileChannel = FileInputStream(fileDescriptor.fileDescriptor).channel
        val startOffset = fileDescriptor.startOffset
        val declaredLength = fileDescriptor.length // Use length instead of declaredLength

        val modelBuffer = fileChannel.map(
                FileChannel.MapMode.READ_ONLY,
                startOffset,
                declaredLength
        )
        interpreter = Interpreter(modelBuffer)

        inputStream.close()
        fileDescriptor.close()
    }

    fun analyzeSpiral(bitmap: Bitmap): Float {
        val inputBuffer = convertBitmapToByteBuffer(bitmap)
        val output = Array(1) { FloatArray(1) }
        interpreter.run(inputBuffer, output)
        return output[0][0]
    }

    private fun convertBitmapToByteBuffer(bitmap: Bitmap): ByteBuffer {
        val inputBuffer = ByteBuffer.allocateDirect(224 * 224 * 3 * 4)
                .order(ByteOrder.nativeOrder())

        val resizedBitmap = Bitmap.createScaledBitmap(bitmap, 224, 224, true)
        val intValues = IntArray(224 * 224)
        resizedBitmap.getPixels(intValues, 0, 224, 0, 0, 224, 224)

        var pixel = 0
        for (i in 0 until 224) {
            for (j in 0 until 224) {
                val value = intValues[pixel++]
                inputBuffer.putFloat(((value shr 16) and 0xFF) / 255.0f)
                inputBuffer.putFloat(((value shr 8) and 0xFF) / 255.0f)
                inputBuffer.putFloat((value and 0xFF) / 255.0f)
            }
        }
        return inputBuffer
    }

    fun close() {
        interpreter.close()
    }
}
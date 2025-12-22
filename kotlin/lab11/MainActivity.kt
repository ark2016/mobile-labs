package com.example.svdcalculator

import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.ScrollView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.google.gson.Gson
import com.google.gson.JsonSyntaxException
import kotlinx.coroutines.*
import kotlin.math.*

/**
 * SVD Calculator
 *
 * Формат ввода JSON:
 * [[1,2,3],[4,5,6]]
 *
 * или с пробелами:
 * [[1, 2, 3], [4, 5, 6]]
 */
class MainActivity : AppCompatActivity() {

    private lateinit var etInput: EditText
    private lateinit var btnCalculate: Button
    private lateinit var tvResult: TextView
    private lateinit var scrollView: ScrollView

    private val svdDecomposition = SVDDecomposition()
    private val gson = Gson()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        etInput = findViewById(R.id.etInput)
        btnCalculate = findViewById(R.id.btnCalculate)
        tvResult = findViewById(R.id.tvResult)
        scrollView = findViewById(R.id.scrollView)

        // Пример данных
        etInput.setText("[[1,2,3],[4,5,6],[7,8,9]]")

        btnCalculate.setOnClickListener {
            performSVD()
        }
    }

    private fun performSVD() {
        val input = etInput.text.toString().trim()

        if (input.isEmpty()) {
            tvResult.text = "Ошибка: введите матрицу"
            return
        }

        tvResult.text = "Вычисление...\n"
        scrollView.post { scrollView.fullScroll(ScrollView.FOCUS_DOWN) }

        // Выполняем вычисления в фоновом потоке
        CoroutineScope(Dispatchers.Default).launch {
            try {
                // Парсинг JSON
                val matrix = parseMatrix(input)

                if (matrix.isEmpty() || matrix[0].isEmpty()) {
                    withContext(Dispatchers.Main) {
                        tvResult.text = "Ошибка: пустая матрица"
                    }
                    return@launch
                }

                val m = matrix.size
                val n = matrix[0].size

                val result = StringBuilder()
                result.append("=== SVD РАЗЛОЖЕНИЕ ===\n\n")
                result.append("Входная матрица A ($m x $n):\n")
                result.append(MatrixUtils.matrixToString(matrix))
                result.append("\n")

                // Собственная реализация
                val startCustom = System.currentTimeMillis()
                val svdCustom = svdDecomposition.decompose(matrix)
                val timeCustom = System.currentTimeMillis() - startCustom

                result.append("--- СОБСТВЕННАЯ РЕАЛИЗАЦИЯ (метод Данилевского) ---\n")
                result.append("Время: ${timeCustom}ms\n\n")

                result.append("Матрица U ($m x $m):\n")
                result.append(MatrixUtils.matrixToString(svdCustom.U))
                result.append("\n")

                result.append("Матрица Σ ($m x $n):\n")
                result.append(MatrixUtils.matrixToString(svdCustom.Sigma))
                result.append("\n")

                result.append("Матрица V^T ($n x $n):\n")
                result.append(MatrixUtils.matrixToString(svdCustom.VT))
                result.append("\n")

                result.append("Сингулярные значения:\n")
                result.append(svdCustom.singularValues.joinToString(", ") { "%.6f".format(it) })
                result.append("\n\n")

                // Проверка точности
                val error = svdDecomposition.verify(matrix, svdCustom)
                result.append("Максимальная ошибка реконструкции: %.10e\n".format(error))

                // Проверка ортогональности
                val orthU = svdDecomposition.checkOrthogonalityU(svdCustom)
                val orthV = svdDecomposition.checkOrthogonalityV(svdCustom)
                result.append("Ортогональность U (||U^T U - I||): %.10e\n".format(orthU))
                result.append("Ортогональность V (||V V^T - I||): %.10e\n".format(orthV))
                result.append("\n")

                withContext(Dispatchers.Main) {
                    tvResult.text = result.toString()
                    scrollView.post { scrollView.fullScroll(ScrollView.FOCUS_DOWN) }
                }

            } catch (e: JsonSyntaxException) {
                withContext(Dispatchers.Main) {
                    tvResult.text = "Ошибка парсинга JSON:\n${e.message}\n\nФормат: [[1,2,3],[4,5,6]]"
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    tvResult.text = "Ошибка: ${e.message}\n${e.stackTraceToString()}"
                }
            }
        }
    }

    private fun parseMatrix(input: String): Array<DoubleArray> {
        // Используем Gson для парсинга JSON
        val rawMatrix = gson.fromJson(input, Array<Array<Number>>::class.java)

        // Конвертируем в Array<DoubleArray>
        return Array(rawMatrix.size) { i ->
            DoubleArray(rawMatrix[i].size) { j ->
                rawMatrix[i][j].toDouble()
            }
        }
    }
}

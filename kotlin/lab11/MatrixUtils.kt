package com.example.svdcalculator

import kotlin.math.*

/**
 * Вспомогательные функции для работы с матрицами и векторами.
 */
object MatrixUtils {

    private const val EPS = 1e-12

    /**
     * Создаёт единичную матрицу n×n.
     */
    fun identity(n: Int): Array<DoubleArray> {
        return Array(n) { i ->
            DoubleArray(n) { j -> if (i == j) 1.0 else 0.0 }
        }
    }

    /**
     * Глубокая копия матрицы.
     */
    fun copy(matrix: Array<DoubleArray>): Array<DoubleArray> {
        return Array(matrix.size) { i -> matrix[i].copyOf() }
    }

    /**
     * Транспонирование матрицы.
     */
    fun transpose(matrix: Array<DoubleArray>): Array<DoubleArray> {
        val m = matrix.size
        val n = matrix[0].size
        return Array(n) { j ->
            DoubleArray(m) { i -> matrix[i][j] }
        }
    }

    /**
     * Умножение матриц A (m×k) * B (k×n) = C (m×n).
     */
    fun multiply(A: Array<DoubleArray>, B: Array<DoubleArray>): Array<DoubleArray> {
        val m = A.size
        val k = A[0].size
        val n = B[0].size

        require(B.size == k) { "Несовместимые размеры матриц: A[${m}x${k}] * B[${B.size}x${n}]" }

        return Array(m) { i ->
            DoubleArray(n) { j ->
                var sum = 0.0
                for (l in 0 until k) {
                    sum += A[i][l] * B[l][j]
                }
                sum
            }
        }
    }

    /**
     * Умножение матрицы на вектор (матрица A (m×n), вектор v (n×1) = результирующий вектор (m×1)).
     */
    fun multiply(A: Array<DoubleArray>, v: DoubleArray): DoubleArray {
        val m = A.size
        val n = A[0].size
        require(v.size == n) { "Несовместимые размеры: матрица ${m}x${n}, вектор ${v.size}" }

        val result = DoubleArray(m)
        for (i in 0 until m) {
            var sum = 0.0
            for (j in 0 until n) {
                sum += A[i][j] * v[j]
            }
            result[i] = sum
        }
        return result
    }

    /**
     * Норма Фробениуса матрицы.
     */
    fun frobeniusNorm(matrix: Array<DoubleArray>): Double {
        var sum = 0.0
        for (row in matrix) {
            for (value in row) {
                sum += value * value
            }
        }
        return sqrt(sum)
    }

    /**
     * Скалярное произведение двух векторов.
     */
    fun dot(v1: DoubleArray, v2: DoubleArray): Double {
        require(v1.size == v2.size) { "Размеры векторов не совпадают." }
        var sum = 0.0
        for (i in v1.indices) {
            sum += v1[i] * v2[i]
        }
        return sum
    }

    /**
     * Евклидова норма (длина) вектора.
     */
    fun norm(v: DoubleArray): Double {
        return sqrt(v.sumOf { it * it })
    }

    /**
     * Перестановка строк матрицы.
     */
    fun swapRows(a: Array<DoubleArray>, i: Int, j: Int) {
        if (i == j) return
        val tmp = a[i]
        a[i] = a[j]
        a[j] = tmp
    }

    /**
     * Перестановка столбцов матрицы.
     */
    fun swapCols(a: Array<DoubleArray>, i: Int, j: Int) {
        if (i == j) return
        for (r in a.indices) {
            val tmp = a[r][i]
            a[r][i] = a[r][j]
            a[r][j] = tmp
        }
    }

    /**
     * Заполняет столбец матрицы случайными значениями и нормализует его.
     */
    fun fillRandomColumn(A: Array<DoubleArray>, col: Int) {
        val m = A.size
        for (i in 0 until m) {
            A[i][col] = Math.random() - 0.5 // Значения в диапазоне [-0.5, 0.5]
        }
        val norm = normCol(A, col, m)
        if (norm > EPS) {
            for (i in 0 until m) A[i][col] /= norm
        } else {
            // Если случайный вектор оказался нулевым, заполняем базисным
            fillBasisColumn(A, col)
        }
    }

    /**
     * Заполняет вектор случайными значениями и нормализует его.
     */
    fun fillRandomVector(v: DoubleArray) {
        for (i in v.indices) {
            v[i] = Math.random() - 0.5
        }
        val norm = norm(v)
        if (norm > EPS) {
            for (i in v.indices) v[i] /= norm
        } else {
            // Если случайный вектор оказался нулевым, заполняем базисным (если возможно)
            if (v.isNotEmpty()) {
                v[0] = 1.0
                for(i in 1 until v.size) v[i] = 0.0
            }
        }
    }

    /**
     * Заполняет столбец стандартным базисным вектором e_j (или e_{j mod m}).
     */
    fun fillBasisColumn(A: Array<DoubleArray>, col: Int) {
        val m = A.size
        for (i in 0 until m) A[i][col] = 0.0
        if (m > 0) { // Убедимся, что матрица не пустая
            A[col % m][col] = 1.0
        }
    }

    /**
     * Скалярное произведение столбцов матрицы.
     */
    fun dotCols(A: Array<DoubleArray>, c1: Int, c2: Int, m: Int): Double {
        var s = 0.0
        for (i in 0 until m) s += A[i][c1] * A[i][c2]
        return s
    }

    /**
     * Норма (длина) столбца матрицы.
     */
    fun normCol(A: Array<DoubleArray>, c: Int, m: Int): Double {
        var s = 0.0
        for (i in 0 until m) s += A[i][c] * A[i][c]
        return sqrt(s)
    }

    /**
     * Вывод матрицы в строку (для отладки).
     */
    fun toString(matrix: Array<DoubleArray>, precision: Int = 4): String {
        val format = "%.${precision}f"
        return matrix.joinToString("\n") { row ->
            row.joinToString("  ") { format.format(it) }
        }
    }

    /**
     * Алиас для toString (для совместимости).
     */
    fun matrixToString(matrix: Array<DoubleArray>, precision: Int = 4): String {
        return toString(matrix, precision)
    }
}

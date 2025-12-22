package com.example.svdcalculator

import kotlin.math.abs
import kotlin.math.sqrt

data class EigenResult(
    val eigenvalues: DoubleArray,
    val eigenvectors: Array<DoubleArray>
)

object DanilevskiyMethod {

    private const val EPS = 1e-9

    /* =========================
       Точка входа
       ========================= */
    fun findEigen(matrix: Array<DoubleArray>): EigenResult {
        return if (isSymmetric(matrix)) {
            println("DEBUG: Matrix is symmetric → using Jacobi method")
            jacobiEigen(matrix)
        } else {
            println("DEBUG: Matrix is NOT symmetric → using Danilevskiy method")
            danilevskiyEigen(matrix)
        }
    }

    fun findEigenvalues(matrix: Array<DoubleArray>): DoubleArray {
        return findEigen(matrix).eigenvalues
    }

    /* =========================
       Проверка симметричности
       ========================= */
    private fun isSymmetric(a: Array<DoubleArray>): Boolean {
        val n = a.size
        for (i in 0 until n) {
            for (j in i + 1 until n) {
                if (abs(a[i][j] - a[j][i]) > EPS) return false
            }
        }
        return true
    }

    /* =========================
       Метод Якоби (для симметричных матриц)
       ========================= */
    private fun jacobiEigen(aInput: Array<DoubleArray>): EigenResult {
        // 1. Копируем исходную матрицу A (не модифицируем оригинал)
        val n = aInput.size
        val a = copyMatrix(aInput)

        // 2. Инициализируем матрицу собственных векторов V = I (единичная матрица)
        // V будет накапливать все ротации
        val v = identityMatrix(n)

        // 3. Основной цикл итераций (максимум 100*n*n итераций)
        // Алгоритм Якоби приводит матрицу к диагональному виду путём ротаций
        repeat(100 * n * n) {
            // 3.1 Найдём наибольший по модулю внедиагональный элемент
            var p = 0
            var q = 1
            var max = abs(a[p][q])

            // 3.2 Проход по верхней треугольной части матрицы (i < j)
            for (i in 0 until n) {
                for (j in i + 1 until n) {
                    val value = abs(a[i][j])
                    if (value > max) {
                        max = value
                        p = i  // строка наибольшего элемента
                        q = j  // столбец наибольшего элемента
                    }
                }
            }

            // 3.3 Критерий сходимости: если максимальный элемент мал, можно завершить
            if (max < EPS) return@repeat

            // 4. Вычисляем угол поворота φ для обнуления элемента a[p][q]
            // Формула: tg(2φ) = 2*a[p][q] / (a[q][q] - a[p][p])
            val phi = 0.5 * kotlin.math.atan2(
                2.0 * a[p][q],
                a[q][q] - a[p][p]
            )

            // 5. Вычисляем коэффициенты ортогональной матрицы вращения:
            //    c = cos(φ), s = sin(φ)
            val c = kotlin.math.cos(phi)
            val s = kotlin.math.sin(phi)

            // 6. Применяем преобразование к столбцам p и q матрицы A (слева)
            // a_ij' = J^T * a_ij * J (левая часть: умножение строк)
            for (i in 0 until n) {
                val aip = a[i][p]
                val aiq = a[i][q]
                a[i][p] = c * aip - s * aiq   // новый элемент a[i][p]
                a[i][q] = s * aip + c * aiq   // новый элемент a[i][q]
            }

            // 7. Применяем преобразование к строкам p и q матрицы A (справа)
            // (правая часть: умножение столбцов)
            for (j in 0 until n) {
                val apj = a[p][j]
                val aqj = a[q][j]
                a[p][j] = c * apj - s * aqj   // новый элемент a[p][j]
                a[q][j] = s * apj + c * aqj   // новый элемент a[q][j]
            }

            // 8. Применяем ту же ротацию к матрице собственных векторов V
            // V := V * J (накапливаем все ротации в V)
            for (i in 0 until n) {
                val vip = v[i][p]
                val viq = v[i][q]
                v[i][p] = c * vip - s * viq   // новый собственный вектор (p-й столбец)
                v[i][q] = s * vip + c * viq   // новый собственный вектор (q-й столбец)
            }
        }

        // 9. Извлекаем собственные значения с диагонали (матрица приведена к диагональному виду)
        val eigenvalues = DoubleArray(n) { a[it][it] }

        // 10. Возвращаем результат: собственные значения и собственные векторы
        return EigenResult(eigenvalues, v)
    }

    /* =========================
       Метод Данилевского
       (произвольная матрица)
       ========================= */
    private fun danilevskiyEigen(aInput: Array<DoubleArray>): EigenResult {
        val n = aInput.size
        var a = copyMatrix(aInput)
        var bTotal = identityMatrix(n)

        for (k in n - 1 downTo 1) {
            val akk1 = a[k][k - 1]
            if (abs(akk1) < EPS) continue

            val m = identityMatrix(n)
            val mInv = identityMatrix(n)

            for (j in 0 until n) {
                m[k - 1][j] = a[k][j] / akk1
            }
            m[k - 1][k - 1] = 1.0 / akk1

            for (j in 0 until n) {
                mInv[k - 1][j] = -a[k][j]
            }
            mInv[k - 1][k - 1] = akk1

            a = multiply(multiply(mInv, a), m)
            bTotal = multiply(bTotal, m)
        }

        val coeffs = DoubleArray(n + 1)
        coeffs[n] = 1.0
        for (i in 0 until n) {
            coeffs[i] = -a[0][n - 1 - i]
        }

        val eigenvalues = solvePolynomial(coeffs)

        val eigenvectors = Array(n) { DoubleArray(n) }
        for (i in eigenvalues.indices) {
            val x = DoubleArray(n)
            x[n - 1] = 1.0
            for (j in n - 2 downTo 0) {
                x[j] = eigenvalues[i] * x[j + 1]
            }
            val v = multiplyVector(bTotal, x)
            normalize(v)
            for (k in 0 until n) {
                eigenvectors[k][i] = v[k]
            }
        }

        return EigenResult(eigenvalues, eigenvectors)
    }

    /* =========================
       Вспомогательные функции
       ========================= */
    private fun solvePolynomial(c: DoubleArray): DoubleArray {
        val n = c.size - 1
        val roots = DoubleArray(n)
        var x = 0.0

        repeat(n) { i ->
            repeat(10000) {
                val fx = poly(c, x)
                val dfx = polyDer(c, x)
                if (abs(dfx) < EPS) return@repeat
                val xNew = x - fx / dfx
                if (abs(xNew - x) < EPS) return@repeat
                x = xNew
            }
            roots[i] = x
            x += 1.0
        }
        return roots
    }

    private fun poly(c: DoubleArray, x: Double): Double {
        var r = 0.0
        for (i in c.indices.reversed()) {
            r = r * x + c[i]
        }
        return r
    }

    private fun polyDer(c: DoubleArray, x: Double): Double {
        var r = 0.0
        for (i in c.indices.reversed().drop(1)) {
            r = r * x + i * c[i]
        }
        return r
    }

    private fun identityMatrix(n: Int): Array<DoubleArray> =
        Array(n) { i -> DoubleArray(n) { if (i == it) 1.0 else 0.0 } }

    private fun copyMatrix(a: Array<DoubleArray>): Array<DoubleArray> =
        Array(a.size) { i -> a[i].clone() }

    private fun multiply(a: Array<DoubleArray>, b: Array<DoubleArray>): Array<DoubleArray> {
        val n = a.size
        val m = b[0].size
        val r = b.size
        val c = Array(n) { DoubleArray(m) }
        for (i in 0 until n)
            for (j in 0 until m)
                for (k in 0 until r)
                    c[i][j] += a[i][k] * b[k][j]
        return c
    }

    private fun multiplyVector(a: Array<DoubleArray>, x: DoubleArray): DoubleArray {
        val r = DoubleArray(a.size)
        for (i in a.indices)
            for (j in x.indices)
                r[i] += a[i][j] * x[j]
        return r
    }

    private fun normalize(v: DoubleArray) {
        val norm = sqrt(v.sumOf { it * it })
        if (norm > EPS) {
            for (i in v.indices) v[i] /= norm
        }
    }
}

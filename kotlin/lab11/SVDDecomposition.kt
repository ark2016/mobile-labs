package com.example.svdcalculator

import kotlin.math.min
import kotlin.math.sqrt

/**
 * SVD: A = U * Sigma * V^*
 */
class SVDDecomposition {

    companion object {
        private const val EPS = 1e-12
        private const val ORTHO_EPS = 1e-10
    }

    data class SVDResult(
        val U: Array<DoubleArray>,          // m×m
        val Sigma: Array<DoubleArray>,      // m×n
        val VT: Array<DoubleArray>,         // n×n
        val singularValues: DoubleArray,    // min(m,n)
        val customEigenvalues: DoubleArray? = null
    )

    fun decompose(A: Array<DoubleArray>): SVDResult {
        val m = A.size
        val n = A[0].size
        val r = min(m, n)

        val AT = MatrixUtils.transpose(A)
        val AAT = MatrixUtils.multiply(A, AT)   // m×m

        val eigen = DanilevskiyMethod.findEigen(AAT)
        val evals = eigen.eigenvalues
        val evecs = eigen.eigenvectors          // m×m, столбцы — собственные векторы

        val order: IntArray =
            evals.indices
                .sortedByDescending { idx -> evals[idx] }
                .toIntArray()

        val sortedEvals = DoubleArray(m) { i -> evals[order[i]] }

        // U: переставим столбцы evecs в порядке убывания λ
        val U = Array(m) { DoubleArray(m) }
        for (col in 0 until m) {
            val srcCol = order[col]
            for (i in 0 until m) {
                U[i][col] = evecs[i][srcCol]
            }
        }

        // σ_i = sqrt(max(λ_i, 0))
        val singularValues = DoubleArray(r) { i ->
            val lambda = sortedEvals[i]
            if (lambda > EPS) sqrt(lambda) else 0.0
        }

        // Sigma: m×n
        val Sigma = Array(m) { DoubleArray(n) }
        for (i in 0 until r) {
            Sigma[i][i] = singularValues[i]
        }

        // V: n×n
        val V = Array(n) { DoubleArray(n) }

        // Первые r столбцов V: v_i = A^T u_i / σ_i
        for (i in 0 until r) {
            val sigma = singularValues[i]
            if (sigma > EPS) {
                val ui = getColumn(U, i)
                val v = multiplyMatrixVector(AT, ui) // A^T * u_i
                for (k in 0 until n) v[k] /= sigma
                setColumn(V, i, v)
            } else {
                MatrixUtils.fillRandomColumn(V, i)
            }
        }

        // Остальные столбцы V добьём случайными
        for (i in r until n) MatrixUtils.fillRandomColumn(V, i)

        // Ортонормализуем U и V (MGS по столбцам)
        mgsOrthonormalizeColumns(U)
        mgsOrthonormalizeColumns(V)

        val VT = MatrixUtils.transpose(V)

        return SVDResult(
            U = U,
            Sigma = Sigma,
            VT = VT,
            singularValues = singularValues,
            customEigenvalues = sortedEvals
        )
    }

    fun verify(A: Array<DoubleArray>, svd: SVDResult): Double {
        val US = MatrixUtils.multiply(svd.U, svd.Sigma)
        val Arec = MatrixUtils.multiply(US, svd.VT)
        val diff = subtractMatrices(A, Arec)
        return MatrixUtils.frobeniusNorm(diff)
    }

    fun checkOrthogonalityU(svd: SVDResult): Double = orthogonalityError(svd.U)

    fun checkOrthogonalityV(svd: SVDResult): Double {
        val V = MatrixUtils.transpose(svd.VT)
        return orthogonalityError(V)
    }

    private fun orthogonalityError(Q: Array<DoubleArray>): Double {
        val QT = MatrixUtils.transpose(Q)
        val I = MatrixUtils.identity(Q.size)
        val prod = MatrixUtils.multiply(QT, Q)
        val diff = subtractMatrices(prod, I)
        return MatrixUtils.frobeniusNorm(diff)
    }

    /* =========================
       Вспомогательные функции
       ========================= */

    private fun subtractMatrices(A: Array<DoubleArray>, B: Array<DoubleArray>): Array<DoubleArray> {
        require(A.size == B.size && A[0].size == B[0].size) { "Несовместимые размеры для вычитания." }
        val m = A.size
        val n = A[0].size
        return Array(m) { i ->
            DoubleArray(n) { j -> A[i][j] - B[i][j] }
        }
    }

    private fun getColumn(A: Array<DoubleArray>, col: Int): DoubleArray =
        DoubleArray(A.size) { i -> A[i][col] }

    private fun setColumn(A: Array<DoubleArray>, col: Int, v: DoubleArray) {
        for (i in A.indices) A[i][col] = v[i]
    }

    private fun multiplyMatrixVector(A: Array<DoubleArray>, x: DoubleArray): DoubleArray {
        val m = A.size
        val n = A[0].size
        require(x.size == n) { "Несовместимые размеры: матрица ${m}x${n}, вектор ${x.size}" }

        val r = DoubleArray(m)
        for (i in 0 until m) {
            var s = 0.0
            for (j in 0 until n) s += A[i][j] * x[j]
            r[i] = s
        }
        return r
    }

    /**
     * Modified Gram-Schmidt по столбцам.
     */
    private fun mgsOrthonormalizeColumns(A: Array<DoubleArray>) {
        val m = A.size
        val n = A[0].size

        for (j in 0 until n) {
            // вычесть проекции на предыдущие
            for (k in 0 until j) {
                var dot = 0.0
                for (i in 0 until m) dot += A[i][k] * A[i][j]
                for (i in 0 until m) A[i][j] -= dot * A[i][k]
            }

            // нормировка
            var norm2 = 0.0
            for (i in 0 until m) norm2 += A[i][j] * A[i][j]
            var norm = sqrt(norm2)

            if (norm < ORTHO_EPS) {
                // если выродилось — перегенерим и попробуем снова
                for (i in 0 until m) A[i][j] = (Math.random() - 0.5)

                for (k in 0 until j) {
                    var dot = 0.0
                    for (i in 0 until m) dot += A[i][k] * A[i][j]
                    for (i in 0 until m) A[i][j] -= dot * A[i][k]
                }

                norm2 = 0.0
                for (i in 0 until m) norm2 += A[i][j] * A[i][j]
                norm = sqrt(norm2)
            }

            if (norm > ORTHO_EPS) {
                for (i in 0 until m) A[i][j] /= norm
            } else {
                // крайний случай: базисный столбец
                for (i in 0 until m) A[i][j] = 0.0
                A[j % m][j] = 1.0
            }
        }
    }
}

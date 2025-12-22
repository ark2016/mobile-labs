package com.example.svdcalculator

import kotlin.math.max
import kotlin.math.sqrt

fun main() {
    val matrix = arrayOf(
        doubleArrayOf(1.0, 2.0, 3.0),
        doubleArrayOf(4.0, 5.0, 6.0),
        doubleArrayOf(7.0, 8.0, 9.0)
    )

    println("Исходная матрица:")
    println(MatrixUtils.toString(matrix))
    println()

    // Проверяем AAT
    val at = MatrixUtils.transpose(matrix)
    val aat = MatrixUtils.multiply(matrix, at)

    println("AAT:")
    println(MatrixUtils.toString(aat))
    println()

    // Собственные значения AAT (через DanilevskiyMethod.findEigen)
    val eigenResult = DanilevskiyMethod.findEigen(aat)
    println("Собственные значения AAT:")
    eigenResult.eigenvalues
        .sortedDescending()
        .forEach { lambda: Double ->
            println("  λ = $lambda, √λ = ${sqrt(max(0.0, lambda))}")
        }
    println()

    val svd = SVDDecomposition()
    val result = svd.decompose(matrix)

    println("Сингулярные значения:")
    result.singularValues.forEach { sigma: Double -> println("  σ = $sigma") }
    println()

    println("Матрица Sigma:")
    println(MatrixUtils.toString(result.Sigma))
    println()

    println("Ошибка реконструкции: ${svd.verify(matrix, result)}")
    println("Ортогональность U: ${svd.checkOrthogonalityU(result)}")
    println("Ортогональность V: ${svd.checkOrthogonalityV(result)}")
}

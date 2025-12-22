package com.example.lab11_firebase

import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.database.DataSnapshot
import com.google.firebase.database.DatabaseError
import com.google.firebase.database.FirebaseDatabase
import com.google.firebase.database.MutableData
import com.google.firebase.database.Transaction

class MainActivity : AppCompatActivity() {

    private val databaseUrl =
        "https://mobile-lab-lebedev-default-rtdb.europe-west1.firebasedatabase.app"
    private val email = "a@mail.ru"
    private val password = "123123"
    private val auth by lazy { FirebaseAuth.getInstance() }
    private val counterRef by lazy {
        FirebaseDatabase.getInstance(databaseUrl).reference.child("counter")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val tvStatus = findViewById<TextView>(R.id.tvStatus)
        val btnIncrement = findViewById<Button>(R.id.btnIncrement)

        btnIncrement.setOnClickListener {
            btnIncrement.isEnabled = false
            tvStatus.text = "Signing in..."
            auth.signInWithEmailAndPassword(email, password).addOnCompleteListener { task ->
                if (!task.isSuccessful) {
                    tvStatus.text = "Sign-in failed"
                    btnIncrement.isEnabled = true
                    return@addOnCompleteListener
                }

                tvStatus.text = "Updating counter..."
                val oldValue = intArrayOf(0)
                counterRef.runTransaction(object : Transaction.Handler {
                    override fun doTransaction(currentData: MutableData): Transaction.Result {
                        val current = currentData.getValue(Int::class.java) ?: 0
                        oldValue[0] = current
                        currentData.value = current + 1
                        return Transaction.success(currentData)
                    }

                    override fun onComplete(
                        error: DatabaseError?,
                        committed: Boolean,
                        currentData: DataSnapshot?
                    ) {
                        if (error != null || !committed) {
                            tvStatus.text = "Update failed"
                        } else {
                            val newValue = currentData?.getValue(Int::class.java) ?: 0
                            tvStatus.text = "Counter: ${oldValue[0]} -> $newValue"
                        }
                        btnIncrement.isEnabled = true
                    }
                })
            }
        }
    }
}

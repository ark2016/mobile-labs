package com.example.lab12_json

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.EditText
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
    private val auth by lazy { FirebaseAuth.getInstance() }
    private val counterRef by lazy {
        FirebaseDatabase.getInstance(databaseUrl).reference.child("counter")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val etEmail = findViewById<EditText>(R.id.etEmail)
        val etPassword = findViewById<EditText>(R.id.etPassword)
        val btnLogin = findViewById<Button>(R.id.btnLogin)
        val tvStatus = findViewById<TextView>(R.id.tvStatus)
        val tvCounter = findViewById<TextView>(R.id.tvCounter)
        val btnIncrement = findViewById<Button>(R.id.btnIncrement)
        val btnShowJson = findViewById<Button>(R.id.btnShowJson)

        btnIncrement.isEnabled = false
        btnShowJson.isEnabled = false

        btnLogin.setOnClickListener {
            val email = etEmail.text.toString().trim()
            val password = etPassword.text.toString()
            if (email.isEmpty() || password.isEmpty()) {
                tvStatus.text = "Enter email and password"
                return@setOnClickListener
            }

            btnLogin.isEnabled = false
            tvStatus.text = "Signing in..."
            auth.signInWithEmailAndPassword(email, password).addOnCompleteListener { task ->
                btnLogin.isEnabled = true
                if (!task.isSuccessful) {
                    tvStatus.text = "Sign-in failed"
                    return@addOnCompleteListener
                }

                tvStatus.text = "Signed in"
                btnIncrement.isEnabled = true
                btnShowJson.isEnabled = true
                loadCounter(tvCounter)
            }
        }

        btnIncrement.setOnClickListener {
            if (auth.currentUser == null) {
                tvStatus.text = "Please sign in"
                return@setOnClickListener
            }

            btnIncrement.isEnabled = false
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
                        tvStatus.text = "Counter updated"
                        tvCounter.text = "Counter: $newValue"
                    }
                    btnIncrement.isEnabled = true
                }
            })
        }

        btnShowJson.setOnClickListener {
            if (auth.currentUser == null) {
                tvStatus.text = "Please sign in"
                return@setOnClickListener
            }
            startActivity(Intent(this, JsonActivity::class.java))
        }
    }

    private fun loadCounter(tvCounter: TextView) {
        counterRef.get().addOnSuccessListener { snapshot ->
            val value = snapshot.getValue(Int::class.java) ?: 0
            tvCounter.text = "Counter: $value"
        }.addOnFailureListener {
            tvCounter.text = "Counter: --"
        }
    }
}

package com.example.lab12_json

import android.os.Bundle
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.google.firebase.auth.FirebaseAuth
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread

class JsonActivity : AppCompatActivity() {

    private val jsonUrl = "https://mysafeinfo.com/api/data?list=nobelwinners&format=json"
    private val auth by lazy { FirebaseAuth.getInstance() }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_json)

        val tvJsonStatus = findViewById<TextView>(R.id.tvJsonStatus)
        val tvJson = findViewById<TextView>(R.id.tvJson)

        tvJsonStatus.text = "Loading..."
        loadJson(tvJsonStatus, tvJson)
    }

    override fun onStart() {
        super.onStart()
        if (auth.currentUser == null) {
            finish()
        }
    }

    private fun loadJson(tvJsonStatus: TextView, tvJson: TextView) {
        thread {
            val result = try {
                val connection = URL(jsonUrl).openConnection() as HttpURLConnection
                connection.requestMethod = "GET"
                connection.connectTimeout = 10000
                connection.readTimeout = 10000
                connection.inputStream.bufferedReader().use { it.readText() }
            } catch (ex: Exception) {
                null
            }

            runOnUiThread {
                if (result == null) {
                    tvJsonStatus.text = "Load failed"
                    tvJson.text = ""
                    return@runOnUiThread
                }

                val formatted = formatNobelWinners(result)
                tvJsonStatus.text = "Loaded"
                tvJson.text = formatted
            }
        }
    }

    private fun formatNobelWinners(rawJson: String): String {
        return try {
            val jsonArray = JSONArray(rawJson)
            val builder = StringBuilder()
            var index = 0
            while (index < jsonArray.length()) {
                val item = jsonArray.getJSONObject(index)
                val id = item.optInt("ID")
                val year = item.optInt("Year")
                val fullName = item.optString("FullName")
                val country = item.optString("Country")
                val award = item.optString("AwardName")

                builder.append("#").append(id)
                    .append(" | ").append(fullName)
                    .append("\n")
                    .append("  Year: ").append(year)
                    .append("  Country: ").append(country)
                    .append("  Award: ").append(award)
                    .append("\n\n")

                index++
            }
            if (builder.isEmpty()) "No data" else builder.toString().trimEnd()
        } catch (ex: Exception) {
            try {
                JSONArray(rawJson).toString(2)
            } catch (_: Exception) {
                rawJson
            }
        }
    }
}

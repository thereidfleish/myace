package com.example.testapplicationemptyactivity.data

import android.util.Log
import com.example.testapplicationemptyactivity.data.model.LoggedInUser
import com.example.testapplicationemptyactivity.networking.RegistrationReq
import com.example.testapplicationemptyactivity.networking.RestApi
import com.example.testapplicationemptyactivity.networking.RegistrationRes
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.io.IOException

/**
 * Class that handles authentication w/ login credentials and retrieves user information.
 */
class LoginDataSource {

    fun login(username: String, displayName: String, biography: String, email: String, password: String): Result<LoggedInUser> {
        try {
            // TODO: handle loggedInUser authentication
            val fakeUser = LoggedInUser(java.util.UUID.randomUUID().toString(), "Jane Doe")
            val retrofit = Retrofit.Builder()
                .baseUrl("https://api.myace.ai/")
                .addConverterFactory(GsonConverterFactory.create())
                .build()
                .create(RestApi::class.java)
            retrofit.register(RegistrationReq(username, displayName, email, password)).enqueue(object :
                Callback<RegistrationRes> {

                /* The HTTP call failed. This method is run on the main thread */
                override fun onFailure(call: Call<RegistrationRes>, t: Throwable) {
                    Log.d("TAG_", "An error happened!")
                    t.printStackTrace()
                }

                /* The HTTP call was successful, we should still check status code and response body
                 * on a production app. This method is run on the main thread */
                override fun onResponse(call: Call<RegistrationRes>, response: Response<RegistrationRes>) {
                    /* This will print the response of the network call to the Logcat */
                    Log.d("TAG_", response.code().toString())
                    Log.d("TAG_", response.errorBody().toString())
                    Log.d("TAG_", response.body().toString())
                }
            })

            return Result.Success(fakeUser)
        } catch (e: Throwable) {
            return Result.Error(IOException("Error logging in", e))
        }
    }

    fun logout() {
        // TODO: revoke authentication
    }
}
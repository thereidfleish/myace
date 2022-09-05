package com.example.testapplicationemptyactivity.networking

import okhttp3.MultipartBody
import okhttp3.RequestBody
import okhttp3.ResponseBody
import retrofit2.Call
import retrofit2.http.*

interface RestApi {

    @Headers("Content-Type: application/json")
    @POST("register/")
    fun register(@Body userData: RegistrationReq): Call<RegistrationRes>

    @Headers("Content-Type: application/json")
    @POST("uploads/")
    fun createUploadURL(@Body videoReq: VideoReq): Call<VideoRes>

    @Headers("Content-Type: application/json")
    @POST("login/")
    fun login(@Body loginReq: LoginReq): Call<SharedData>


    @POST
    @Multipart
    fun uploadToS3(@Url awsUrl: String,
                   @PartMap body: Map<String,@JvmSuppressWildcards RequestBody>,
                   @Part video: MultipartBody.Part
    ): Call<ResponseBody>

    @Headers("Content-Type: application/json")
    @POST
    fun convert(@Url url: String): Call<ResponseBody>
}
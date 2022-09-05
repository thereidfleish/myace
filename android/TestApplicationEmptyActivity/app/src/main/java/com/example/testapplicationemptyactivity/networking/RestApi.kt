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
                   @Part("key") key: RequestBody?,
                   @Part("x-amz-algorithm") xAmzAlgorithm: RequestBody?,
                   @Part("x-amz-credential") xAmzCredential: RequestBody?,
                   @Part("x-amz-date") xAmzDate: RequestBody?,
                   @Part("policy") policy: RequestBody?,
                   @Part("x-amz-signature") xAmzSignature: RequestBody?,
                   @Part video: MultipartBody.Part
    ): Call<ResponseBody>

    @Headers("Content-Type: application/json")
    @POST
    fun convert(@Url url: String): Call<ResponseBody>
}
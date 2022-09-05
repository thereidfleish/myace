package com.example.testapplicationemptyactivity

import android.content.Intent
import android.os.Bundle
import android.provider.MediaStore
import android.util.Log
import android.widget.Button
import androidx.appcompat.app.AppCompatActivity
import com.example.testapplicationemptyactivity.networking.*
import okhttp3.*
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.io.File
import java.net.CookieManager
import java.util.*



class MainActivity : AppCompatActivity() {
    private lateinit var retrofit: RestApi
    private lateinit var s3Uploader: RestApi
    private lateinit var cookieManager: CookieManager
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        val uploadButton: Button =findViewById(R.id.upload)
        val loginButton: Button =findViewById(R.id.login)

        retrofit = Retrofit.Builder()
            .baseUrl("https://api.myace.ai/")
            .client(OkHttpClient().newBuilder().cookieJar(SessionCookieJar()).build())
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(RestApi::class.java)

        uploadButton.setOnClickListener{
//            val intent= Intent(this, LoginActivity::class.java)
//            startActivity(intent)
            val gallery = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.INTERNAL_CONTENT_URI)
            startActivityForResult(gallery, 100)

        }
        loginButton.setOnClickListener{
            login()
        }



    }
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (resultCode == RESULT_OK && requestCode == 100) {
            val uriPathHelper = URIPathHelper()
            var filePath = uriPathHelper.getPath(this, data?.data!!)!!

            Log.d("TAG_onActivityResult", filePath)
//            File("DCIM/").walk().forEach {
//                Log.d("TAG_onActivityResult", it.toString())
//            }

            upload(filePath)
        }
    }

    fun login() {
        retrofit.login(LoginReq("password", "andrew032012@gmail.com","Password1234", null)).enqueue(object :
            Callback<SharedData> {

            /* The HTTP call failed. This method is run on the main thread */
            override fun onFailure(call: Call<SharedData>, t: Throwable) {
                Log.d("TAG_", "An error happened!")
                t.printStackTrace()
            }

            /* The HTTP call was successful, we should still check status code and response body
             * on a production app. This method is run on the main thread */
            override fun onResponse(call: Call<SharedData>, response: Response<SharedData>) {
                /* This will print the response of the network call to the Logcat */
                Log.d("TAG_login", response.code().toString())
                response.errorBody()?.let { Log.d("TAG_", it.string()) }
                Log.d("TAG_login", response.body().toString())
            }
        })
    }
    private class SessionCookieJar : CookieJar {
        private var cookies: List<Cookie>? = null
        override fun saveFromResponse(url: HttpUrl, cookies: List<Cookie>) {
            Log.d("TAG_SessionCookieJar", "saveFromResponse called")
            if (url.encodedPath().endsWith("login/")) {
                Log.d("TAG_SessionCookieJar", "retrieved login cookies")
                this.cookies = ArrayList(cookies)
            }
        }

        override fun loadForRequest(url: HttpUrl): List<Cookie> {
            return if (!url.encodedPath().endsWith("login/") && cookies != null) {
                cookies!!
            } else {
                Collections.emptyList()
            }
        }
    }

    private fun upload(fileURL: String) {
        retrofit.createUploadURL(VideoReq("blah", "title", 78, NewVisibility(VisibilityOptions.private, mutableListOf()))).enqueue(object :
            Callback<VideoRes> {

            /* The HTTP call failed. This method is run on the main thread */
            override fun onFailure(call: Call<VideoRes>, t: Throwable) {
                Log.d("TAG_", "An error happened!")
                t.printStackTrace()
            }

            /* The HTTP call was successful, we should still check status code and response body
             * on a production app. This method is run on the main thread */
            override fun onResponse(call: Call<VideoRes>, response: Response<VideoRes>) {
                /* This will print the response of the network call to the Logcat */
                Log.d("TAG_upload", response.code().toString())
                response.errorBody()?.let { Log.d("TAG_", it.string()) }
                Log.d("TAG_upload", response.body().toString())
                if(response.body() != null) {
                    val responseBody: VideoRes = response.body()!!
                    if(response.code() == 201)
                        uploadToS3(responseBody.url!!, fileURL, responseBody.fields!!, responseBody.id!!)
                }

            }
        })
    }

    private fun uploadToS3(url : String, fileURL : String, field : Field, id : Int) {
        val file = File(fileURL)
        val reqFile = RequestBody.create(MediaType.parse("video/*"), file)
        val body = MultipartBody.Part.createFormData("file", file.name, reqFile)
//        val name = RequestBody.create(MediaType.parse("text/plain"), "upload_test")
        Log.d("TAG_uploadToS3", "Attempting to upload...")

        val bodyMap: HashMap<String, RequestBody> = HashMap()

        createRequestBodyMap(bodyMap, field)

        retrofit.uploadToS3(
            url,
            bodyMap,
            body
        ).enqueue(object : Callback<ResponseBody> {

            /* The HTTP call failed. This method is run on the main thread */
            override fun onFailure(call: Call<ResponseBody>, t: Throwable) {
                Log.d("TAG_uploadToS3", "An error happened!")
                t.printStackTrace()
            }

            /* The HTTP call was successful, we should still check status code and response body
             * on a production app. This method is run on the main thread */
            override fun onResponse(call: Call<ResponseBody>, response: Response<ResponseBody>) {
                /* This will print the response of the network call to the Logcat */
                Log.d("TAG_uploadToS3", response.code().toString())
                response.errorBody()?.let { Log.d("TAG_", it.string()) }
                Log.d("TAG_uploadToS3", response.body().toString())
                convert(id)
            }
        })
    }

    private fun createRequestBodyMap(bodyMap: HashMap<String, RequestBody>, field: Field) {
        bodyMap.put("key",createRequestBody(field.key))
        bodyMap.put("x-amz-algorithm",createRequestBody(field.xAmzAlgorithm))
        bodyMap.put("x-amz-credential",createRequestBody(field.xAmzCredential))
        bodyMap.put("x-amz-date",createRequestBody(field.xAmzDate))
        bodyMap.put("policy",createRequestBody(field.policy))
        bodyMap.put("x-amz-signature",createRequestBody(field.xAmzSignature))
    }

    private fun createRequestBody(value: String?): RequestBody {
        return RequestBody.create(MediaType.parse(MULTIPART_FORM_DATA), value!!)
    }

    companion object{
        const val MULTIPART_FORM_DATA = "multipart/form-data"
    }

    private fun convert(uploadID: Int) {
        retrofit.convert("uploads/$uploadID/convert/").enqueue(object : Callback<ResponseBody> {

            /* The HTTP call failed. This method is run on the main thread */
            override fun onFailure(call: Call<ResponseBody>, t: Throwable) {
                Log.d("TAG_convert", "An error happened!")
                t.printStackTrace()
            }

            /* The HTTP call was successful, we should still check status code and response body
             * on a production app. This method is run on the main thread */
            override fun onResponse(call: Call<ResponseBody>, response: Response<ResponseBody>) {
                /* This will print the response of the network call to the Logcat */
                Log.d("TAG_convert", response.code().toString())
                response.errorBody()?.let { Log.d("TAG_", it.string()) }
                Log.d("TAG_convert", response.body().toString())
            }
        })
    }

}
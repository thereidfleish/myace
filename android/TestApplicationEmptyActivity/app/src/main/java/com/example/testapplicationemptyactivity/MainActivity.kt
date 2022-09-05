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
import java.net.URI
import java.net.URLEncoder
import java.util.*
import kotlin.text.indexOf
import android.content.ContentUris
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract

class URIPathHelper {

    fun getPath(context: Context, uri: Uri): String? {
        val isKitKatorAbove = Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT

        // DocumentProvider
        if (isKitKatorAbove && DocumentsContract.isDocumentUri(context, uri)) {
            // ExternalStorageProvider
            if (isExternalStorageDocument(uri)) {
                val docId = DocumentsContract.getDocumentId(uri)
                val split = docId.split(":".toRegex()).toTypedArray()
                val type = split[0]
                if ("primary".equals(type, ignoreCase = true)) {
                    return Environment.getExternalStorageDirectory().toString() + "/" + split[1]
                }

            } else if (isDownloadsDocument(uri)) {
                val id = DocumentsContract.getDocumentId(uri)
                val contentUri = ContentUris.withAppendedId(Uri.parse("content://downloads/public_downloads"), java.lang.Long.valueOf(id))
                return getDataColumn(context, contentUri, null, null)
            } else if (isMediaDocument(uri)) {
                val docId = DocumentsContract.getDocumentId(uri)
                val split = docId.split(":".toRegex()).toTypedArray()
                val type = split[0]
                var contentUri: Uri? = null
                if ("image" == type) {
                    contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                } else if ("video" == type) {
                    contentUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                } else if ("audio" == type) {
                    contentUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                }
                val selection = "_id=?"
                val selectionArgs = arrayOf(split[1])
                return getDataColumn(context, contentUri, selection, selectionArgs)
            }
        } else if ("content".equals(uri.scheme, ignoreCase = true)) {
            return getDataColumn(context, uri, null, null)
        } else if ("file".equals(uri.scheme, ignoreCase = true)) {
            return uri.path
        }
        return null
    }

    fun getDataColumn(context: Context, uri: Uri?, selection: String?, selectionArgs: Array<String>?): String? {
        var cursor: Cursor? = null
        val column = "_data"
        val projection = arrayOf(column)
        try {
            cursor = context.getContentResolver().query(uri!!, projection, selection, selectionArgs,null)
            if (cursor != null && cursor.moveToFirst()) {
                val column_index: Int = cursor.getColumnIndexOrThrow(column)
                return cursor.getString(column_index)
            }
        } finally {
            if (cursor != null) cursor.close()
        }
        return null
    }

    fun isExternalStorageDocument(uri: Uri): Boolean {
        return "com.android.externalstorage.documents" == uri.authority
    }

    fun isDownloadsDocument(uri: Uri): Boolean {
        return "com.android.providers.downloads.documents" == uri.authority
    }

    fun isMediaDocument(uri: Uri): Boolean {
        return "com.android.providers.media.documents" == uri.authority
    }
}

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
//    // onActivityResult() handles callbacks from the photo picker.
//    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent) {
//        super.onActivityResult(requestCode, resultCode, data)
//        if (resultCode != Activity.RESULT_OK) {
//            // Handle error
//            return
//        }
//        when (requestCode) {
//            REQUEST_PHOTO_PICKER_SINGLE_SELECT -> {
//                // Get photo picker response for single select.
//                val currentUri: Uri = data.data!!
//
//                // Do stuff with the photo/video URI.
//                return
//            }
//            REQUEST_PHOTO_PICKER_MULTI_SELECT -> {
//                // Get photo picker response for multi select.
//                var i = 0
//                var currentUri: Uri
//
//                while (i < data.clipData!!.itemCount) {
//                    currentUri = data.clipData!!.getItemAt(i).uri
//                    // Do stuff with each photo/video URI.
//                    i++
//                }
//                return
//            }
//        }

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
        retrofit.uploadToS3(
            url,
            RequestBody.create(MediaType.parse("multipart/form-data"), field.key),
            RequestBody.create(MediaType.parse("multipart/form-data"), field.xAmzAlgorithm),
            RequestBody.create(MediaType.parse("multipart/form-data"), field.xAmzCredential),
            RequestBody.create(MediaType.parse("multipart/form-data"), field.xAmzDate),
            RequestBody.create(MediaType.parse("multipart/form-data"), field.policy),
            RequestBody.create(MediaType.parse("multipart/form-data"), field.xAmzSignature),
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
package com.example.testapplicationemptyactivity.networking

import com.google.gson.annotations.SerializedName

data class RegistrationReq (
    @SerializedName("username") val username: String?,
    @SerializedName("display_name") val displayName: String?,
    @SerializedName("email") val email: String?,
    @SerializedName("password") val password: String?
)

data class RegistrationRes (
    @SerializedName("id") val id: Int?,
    @SerializedName("username") val username: String?,
    @SerializedName("display_name") val displayName: String?,
    @SerializedName("biography") val biography: String?,
    @SerializedName("email") val email: String?
)

data class VideoReq (
    @SerializedName("filename") val filename: String?,
    @SerializedName("display_title") val displayTitle: String?,
    @SerializedName("bucket_id") val bucketId: Int?,
    @SerializedName("visibility") val visibility: NewVisibility?
)

data class VideoRes (
    @SerializedName("id") val id: Int?,
    @SerializedName("url") val url: String?,
    @SerializedName("fields") val fields: Field?,
)

data class Field (
    @SerializedName("key") val key: String?,
    @SerializedName("x_amz_algorithm") val xAmzAlgorithm: String?,
    @SerializedName("x_amz_credential") val xAmzCredential: String?,
    @SerializedName("x_amz_date") val xAmzDate: String?,
    @SerializedName("policy") val policy: String?,
    @SerializedName("x_amz_signature") val xAmzSignature: String?
)

data class NewVisibility (
    @SerializedName("default") val default: VisibilityOptions?,
    @SerializedName("also_shared_with") val alsoSharedWith: MutableList<Int>?
)

enum class VisibilityOptions(val string: String) {
    `private`("private"),
    coaches_only("coaches-only"),
    friends_only("friends-only"),
    friends_and_coaches("friends-and-coaches"),
    `public`("public")
}

data class LoginReq(
    @SerializedName("method") val method: String,
    @SerializedName("email") val email: String?,
    @SerializedName("password") val password: String?,
    @SerializedName("token") val token: String?
)

data class SharedData(
    @SerializedName("id") val id: Int?,
    @SerializedName("n_courtships") val nCourtships: CourtshipTypeQuantity?,
    @SerializedName("username") val username: String?,
    @SerializedName("display_name") val displayName: String?,
    @SerializedName("biography") val biography: String?,
    @SerializedName("courtship") val courtship: Courtship?,
    @SerializedName("n_uploads") val nUploads: Int?,
    @SerializedName("email") val email: String?,
    @SerializedName("email_confirmed") val emailConfirmed: Boolean?
)

data class CourtshipTypeQuantity(
    @SerializedName("friends") val friends: Int?,
    @SerializedName("coaches") val coaches: Int?,
    @SerializedName("students") val students: Int?
)

data class Courtship(
    @SerializedName("type") val type: CourtshipType,
    @SerializedName("dir") val dir: CourtshipRequestDir?,
)
enum class CourtshipType(val string: String) {
    friend("friend"),
    coach("coach"),
    student("student"),
    friend_req("friend-req"),
    coach_req("coach-req"),
    student_req("student-req"),
    undefined("undefined")
}

enum class CourtshipRequestDir(val string: String) {
    `in`("int"),
    `out`("out")
}
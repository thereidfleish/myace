//
//  Styles.swift
//  AI Tennis Coach (iOS)
//
//  Created by AndrewC on 1/17/22.
//

import SwiftUI

/* General button style */
struct button: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .background(Color.green)
            .cornerRadius(10)
            .foregroundColor(.white)
    }
}

/* Used in bucket folders and student folders */
struct navigationLink: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.green)
            .cornerRadius(10)
            .padding(.horizontal)
            .shadow(radius: 5)
    }
}

/* Used just for bucket name when editing property internally */
struct bucketName: ViewModifier {
    let font = Font.system(.title2).weight(.heavy)
    func body(content: Content) -> some View {
        content
            .font(font)
    }
}

/* Bucket info displayed on the outside (name, date last updated, etc.) */
struct bucketTextExternal: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .foregroundColor(Color.white)
    }
}

/* Unread Bucket info displayed on the outside (name, date last updated, etc.), bolded */
struct unreadBucketTextExternal: ViewModifier {
    let font = Font.system(.subheadline).weight(.bold)
    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(Color.white)
    }
}

/* Bucket info displayed when editing */
struct bucketTextInternal: ViewModifier {
    let font = Font.system(.headline).weight(.bold)
    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(Color.green)
    }
}

/* Uploaded video info */
struct videoInfo: ViewModifier {
    let font = Font.system(.headline).weight(.heavy)
    func body(content: Content) -> some View {
        content
            .font(font)
    }
}

/* Profile text displayed */
struct profileText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .foregroundColor(.green)
    }
}

/* Profile info specific to a user (number of videos, friends, their name, etc.) */
struct profileInfo: ViewModifier {
    let font = Font.system(.headline).weight(.heavy)
    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(.green)
    }
}

extension View {
    func buttonStyle() -> some View {
        modifier(button())
    }
    func navigationLinkStyle() -> some View {
        modifier(navigationLink())
    }
    func bucketNameStyle() -> some View {
        modifier(bucketName())
    }
    func bucketTextExternalStyle() -> some View {
        modifier(bucketTextExternal())
    }
    func unreadBucketTextExternalStyle() -> some View {
        modifier(unreadBucketTextExternal())
    }
    func bucketTextInternalStyle() -> some View {
        modifier(bucketTextInternal())
    }
    func videoInfoStyle() -> some View {
        modifier(videoInfo())
    }
    func profileTextStyle() -> some View {
        modifier(profileText())
    }
    func profileInfoStyle() -> some View {
        modifier(profileInfo())
    }
}

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

/* General button style */
struct textField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .autocapitalization(.none)
            .padding(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.green, lineWidth: 3)
            )
    }
}

/* Used in bucket folders and student folders */
struct navigationLink: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.green)
            .cornerRadius(10)
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

/* The style of the text depicting the friend status on a UserCardView */
struct friendStatusText: ViewModifier {
    let font = Font.system(.caption)
    func body(content: Content) -> some View {
        content
            .font(font)
            .padding(.top, 2)
    }
}

/* The style of the friend status background on a UserCardView */
struct friendStatusBackground: ViewModifier {
    let font = Font.system(.caption)
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .foregroundColor(.green)
    }
}

extension View {
    func buttonStyle() -> some View {
        modifier(button())
    }
    func textFieldStyle() -> some View {
        modifier(textField())
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
    func friendStatusTextStyle() -> some View {
        modifier(friendStatusText())
    }
    func friendStatusBackgroundStyle() -> some View {
        modifier(friendStatusBackground())
    }
}

import React from 'react';
import Team from './Team'

export default function About() {

  return (
    <div id="about">
      <div style={{ padding: '20px 50px'}}>
        <h2>The motivation</h2>
        <p>
          <strong>My Ace</strong> is focused on driving player-coach interactions. 
          Our aim is to facilitate quality coaching through digitital technology.
          Currently, when players record either their matches or individual strokes
          they find it difficult to quickly obtain high-quality feedback from a coach.
          Through our development of a novel tennis platform, we will facilitate the quick
          and efficient feedback of player's videos.
        </p>
        <h2>Our end goal</h2>
        <p>
          Following the release of our beta app on iOS, we will be implementing
          a modern, platform-independent coach portal to increase the
          efficiency of annotating videos. We also plan to bring this web
          application to mobile, welcoming non-iOS users to our platform.
          Through the development of our Marketplace feature, we will make
          professional coaching accessible to all skill levels. <strong>Think
            cameo, but for tennis. Imagine saying that Nadal is your tennis
            coach!</strong>
        </p>
        <h2>Meet the team</h2>
        <Team />
      </div>
    </div>
  );
}

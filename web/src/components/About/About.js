import React from 'react';
import Header from '../Header/Header';
import Timeline from '../Timeline/Timeline'
import Team from './Team'

export default function About() {

  return (
    <div>
      <Header />
      <div style={{ padding: '20px 50px'}}>
        <Timeline />
        <h2>The motivation</h2>
        <p>
          My-Ace is focused on driving player-coach interactions. 
          Our aim is to facilitate quality coaching through digitital technology.
          Currently, when players record either their matches or individual strokes
          they find it difficult to get quick high-quality feedback from a coach.
          Through our development of a novel tennis platform, we will facilitate the quick
          and efficient feedback of player's videos. <strong>Think cameo, but for tennis.
          Imagine saying that Nadal is your tennis coach!</strong>
        </p>
        <h2>Our end goal</h2>
        <p>
          Following the release of our consumer product, we will be implementing a machine learning model
          that will offer automatated advice to players. As more player's upload their vidoes to our platform
          our automated advice will continue to get better!
        </p>
        <h2>Meet the team</h2>
        <Team />
      </div>
    </div>
  );
}

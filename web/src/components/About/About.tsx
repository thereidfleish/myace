import React from 'react';
import Header from '../Header/Header';
import './About.scss'

export default function About() {
  const pics = [
    'https://media.tarkett-image.com/large/TH_24567080_24594080_24596080_24601080_24563080_24565080_24588080_001.jpg',
    ''
  ]
  
  return (
    <div>
      <Header />
      <div style={{ padding: '20px 50px'}}>
        <h3>What is myace?</h3>
        <h3>Why we're better</h3>
        <h3>Meet the team</h3>
        <div className='d-flex flex-wrap justify-content-center'>
          {
            pics.map((pic, i) => {
              return (
                <div className='team-pic' key={i}>
                  
                </div>
              )
            })
          }
        </div>
      </div>
    </div>
  );
}

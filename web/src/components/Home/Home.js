import React from 'react';
import Button from 'react-bootstrap/Button'
import './Home.scss'
import Timeline from './Timeline/Timeline'
import About from './About/About'
// import Fund from './Fund/Fund'
import Alpha from './Alpha/Alpha'

export default function Home() {
  return (
    <div>
        <div style= {{ height: '80vh'}} className='d-flex flex-column justify-content-center'>
            <div className='d-flex flex-column align-items-center'>
                <h1 className='main-font'>My Ace 🎾</h1>
                <p className="mb-2 text-muted baby-font">tennis training on the go</p>
                <a href="#about"><Button style={{ marginTop: '15px'}}>
                    <span style={{ color: 'white'}}>learn more →</span>
                </Button></a>
            </div>
        </div>
      <Timeline />
      <About />
      {/* <Fund /> */}
      <Alpha />
    </div>
  );
}

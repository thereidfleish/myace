import React from 'react';
import Button from 'react-bootstrap/Button'
import './Home.scss'
import Timeline from './Timeline/Timeline'
import About from './About/About'

export default function Home() {
  return (
    <div>
      <div style={{ height: '95vh' }} className='d-flex flex-column justify-content-center'>
        <div className='d-flex flex-column align-items-center'>
          <h1 className='main-font'>
            My Ace
            <img
              style={{
                width: "4rem",
                paddingBottom: "0.8rem",
                marginLeft: "1rem"
              }}
              src="https://myace.ai/logo.svg"
              alt="My Ace logo"
            />
          </h1>
          <p className="mb-2 text-muted baby-font">tennis training on the go</p>
          <a href="#about"><Button style={{ marginTop: '15px' }}>
            <span style={{ color: 'white' }}>learn more →</span>
          </Button></a>
        </div>
      </div>
      <Timeline />
      <About />
    </div>
  );
}

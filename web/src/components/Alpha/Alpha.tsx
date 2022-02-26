import React from 'react'
import ReactPlayer from 'react-player'
import Header from '../Header/Header'
import Timeline from '../Timeline/Timeline'


export default function Alpha() {
  return (
    <div>
        <Header />
        <div style={{ padding: '20px 50px'}}>
        <Timeline />
        <h2>02/14 - Courtships</h2>
        <div style={{ margin: '0px auto'}} className="d-flex justify-content-center">
            <ReactPlayer url='https://youtu.be/yt9lXFM_yds' />
        </div>
        <h2 style={{ marginTop: '20px' }}>01/04 - Basic App</h2>
        <div style={{ margin: '0px auto'}} className="d-flex justify-content-center">
            <ReactPlayer url='https://www.youtube.com/watch?v=kRng8GSa63I' />
        </div>
      </div>
    </div>
  )
}

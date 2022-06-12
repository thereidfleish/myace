import React from 'react'
import ReactPlayer from 'react-player'

export default function Alpha() {
  return (
    <div>
        <div style={{ padding: '20px 50px'}}>
        <h2>Development</h2>
        <div>
          <p><strong>My Ace</strong> beta will launch in June, 2022. Check out our latest alpha below!
        </p>
        </div>
        <div style={{ margin: '0px auto'}} className="d-flex justify-content-center">
            <ReactPlayer url='https://youtu.be/yt9lXFM_yds' />
        </div>
      </div>
    </div>
  )
}

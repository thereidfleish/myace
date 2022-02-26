import React from 'react'
import TimelineEntry from './TimelineEntry'

export default function Timeline() {
  const timelines = [
      {
          contents: [
              "Base Backend Infrastructure",
              "Base Frontend Infrastructure"
          ],
          date: "January 2022"
      },
      {
          contents: [
              "Alpha App Store Release",
              "Coaching Web Portal"
          ],
          date: 'February 2022'
      },
      {
        contents: [
            "Beta App Store Release",
            "Customer Aquisition Strategy"
        ],
        date: 'March 2022'
        }
      
  ]

    return (
        <div>
            <h3 style={{ textAlign: 'center' }}>Project Timeline</h3>
            <div id="vertical-timeline" className='d-flex justify-content-center'>
                {
                    timelines.map((timeline, i) => {
                        return (
                            <TimelineEntry
                                contents={timeline.contents}
                                date={timeline.date}
                                key={i}
                            />
                        )
                    })
                }
            </div>
            <div id="horizontal-timeline" className='d-flex justify-content-center'>
                {
                    timelines.map((timeline, i) => {
                        return (
                            <TimelineEntry
                                contents={timeline.contents}
                                date={timeline.date}
                                key={i}
                            />
                        )
                    })
                }
            </div>
        </div>
        
    )
}

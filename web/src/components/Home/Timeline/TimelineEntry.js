import React from 'react'
import './Timeline.scss'

export default function TimelineEntry(props) {
    return (
        <div>
            <div id="horizontal-timeline" className='d-flex flex-column align-items-right'>
                <div className='d-flex align-items-center shapes-container'>
                    <div className="rectangle-connector" />
                    <div className="circle-connector" />
                    <div className="rectangle-connector" />
                </div>
                
                <div className="text-container">
                    <p className='descriptor-title'>
                        {props.date}
                    </p>
                    {
                        props.contents.map((content, i) => {
                            return (
                                <p key={i} className='descriptor-element'>
                                    {content}
                                </p>
                            )
                        })
                    }
                </div>
            </div>
            <div id="vertical-timeline">
                <div className="d-flex flex-column align-items-center">
                    <div className="rectangle-connector-vertical" />
                    <div className="text-container">
                        <p className='descriptor-title'>
                            {props.date}
                        </p>
                        {
                            props.contents.map((content, i) => {
                                return (
                                    <p key={i} className='descriptor-element'>
                                        {content}
                                    </p>
                                )
                            })
                        }
                    </div>
                </div>
                    
            </div>
        </div>   
    )
}

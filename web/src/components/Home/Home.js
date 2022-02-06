import React from 'react';
import { Link } from 'react-router-dom'
import Button from 'react-bootstrap/Button'
import Header from '../Header/Header'
import './Home.scss'

export default function Home() {
  return (
    <div>
        <Header />
        <div style= {{ height: '80vh'}} className='d-flex flex-column justify-content-center'>
            <div className='d-flex flex-column align-items-center'>
                <h1 className='main-font'>myace.ai</h1>
                <p className="mb-2 text-muted baby-font">the world's premier ai training app</p>
                <Link to="/about"><Button style={{ marginTop: '15px'}}>
                    <span style={{ color: 'white'}}>learn more →</span>
                </Button></Link>
            </div>
        </div>
    </div>
    
  );
}

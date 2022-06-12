import React from 'react'
import {Link} from 'react-router-dom'
import Navbar from 'react-bootstrap/Navbar'


export default function Header() {

    return (
        <Navbar style={{ margin: '0px 30px', borderBottom: '2px solid lightgrey', height: "5vh" }}>
            <Link to="/" style={{ textDecoration: 'none' }}><Navbar.Brand href="">
                <img 
                    style={{ 
                        width: "2rem"
                    }}
                    src="https://myace.ai/logo.svg"
                    alt="My Ace logo"
                    />
            </Navbar.Brand></Link>
            <Navbar.Toggle />
            <Navbar.Collapse className="justify-content-end">
                <Link to="/contact" style={{ textDecoration: 'none' }}><Navbar.Text style={{ cursor: 'pointer'}}>
                    <span style={{ color: '#7ac07a', marginRight: '20px' }}>Contact Us</span>
                </Navbar.Text></Link>
            </Navbar.Collapse>
        </Navbar>
    )
}

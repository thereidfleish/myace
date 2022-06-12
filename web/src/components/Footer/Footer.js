import React from 'react'
import {Link} from 'react-router-dom'


export default function Footer() {

    return (
        <div style={{ backgroundColor: '#8AD28A', padding: "1rem" }}>
            <Link to="/" style={{ color: "white", marginRight: "1rem", textDecoration: 'none' }}>
                Home
            </Link>
            <Link to="/privacy" style={{ color: "white", marginRight: "1rem", textDecoration: 'none' }}>
                Privacy Policy
            </Link>
            <Link to="/contact" style={{ color: "white", marginRight: "1rem", textDecoration: 'none' }}>
                Contact Us
            </Link>
        </div>
    )
}

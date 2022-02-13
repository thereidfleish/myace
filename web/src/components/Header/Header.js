import React from 'react'
import {Link} from 'react-router-dom'
import Navbar from 'react-bootstrap/Navbar'


export default function Header() {

    return (
        <Navbar style={{ margin: '0px 30px', borderBottom: '2px solid lightgrey' }}>
            <Link to="/" style={{ textDecoration: 'none' }}><Navbar.Brand href="">
                <strong>myace.ai</strong>
            </Navbar.Brand></Link>
            <Navbar.Toggle />
            <Navbar.Collapse className="justify-content-end">
                <Link to="/coaches" style={{ textDecoration: 'none' }}><Navbar.Text style={{ cursor: 'pointer'}}>
                    <span style={{ color: '#8AD28A', marginRight: '20px' }}>coches</span>
                </Navbar.Text></Link>
                <Link to="/fund" style={{ textDecoration: 'none' }}><Navbar.Text style={{ cursor: 'pointer'}}>
                    <span style={{ color: '#8AD28A', marginRight: '20px'}}>fund</span>
                </Navbar.Text></Link>
                <Link to="/about" style={{ textDecoration: 'none' }}><Navbar.Text style={{ cursor: 'pointer'}}>
                    <span style={{ color: '#8AD28A' }}>about</span>
                </Navbar.Text></Link>
            </Navbar.Collapse>
        </Navbar>
    )
}

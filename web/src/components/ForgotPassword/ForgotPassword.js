import React, { useState } from 'react';
import { useLocation } from 'react-router-dom';

export default function ForgotPassword() {
  const [pwd, setPwd] = useState("");
  const [confirmPwd, setConfirmPwd] = useState("");
  const [successMsg, setSuccessMsg] = useState("");
  // get token URL parameter
  const search = useLocation().search;
  const token = new URLSearchParams(search).get('token');
  const initial_error_msg = token ? "" : "This link is invalid. No specified token."
  const [errorMsg, setErrorMsg] = useState(initial_error_msg);

  const changePwd = (e) => {
    setPwd(e.target.value)
  }

  const changeConfirmPwd = (e) => {
    setConfirmPwd(e.target.value)
  }

  function handleSubmit(e) {
      e.preventDefault()
      setErrorMsg("");
      setSuccessMsg("");
      // ensure password fields match
      if (pwd !== confirmPwd) {
        setErrorMsg("Passwords do not match!");
        return;
      }
      // POST request using fetch inside useEffect React hook
      const requestOptions = {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(
            {
              password: pwd,
              token: token
            })
      };
      fetch('https://api.myace.ai/callbacks/forgot/', requestOptions)
          .then(async response => {
            let data = await response.json();
            if (data.error) {
              setErrorMsg(data.error)
            }
            if (response.ok) {
              setSuccessMsg("Password saved!")
            }
          })
          .catch(e => setErrorMsg);

  // empty dependency array means this effect will only run once (like componentDidMount in classes)
  };
  return (
    <div style={{ marginTop: '20px' }} className='d-flex flex-column align-items-center'>
      <h2>Forgot Password</h2>
      {errorMsg && 
        <p style={{ color: "red" }}>{ errorMsg }</p>
      }
      {successMsg && 
        <p style={{ color: "green" }}>{ successMsg }</p>
      }
      <form>
        <label>New password:</label><br/>
        <input type="password" onChange={changePwd}/><br/>
        <label>Confirm password:</label><br/>
        <input type="password" onChange={changeConfirmPwd}/>
        <button onClick={handleSubmit}>Submit</button>
      </form>
    </div>
  );
}

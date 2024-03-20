import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';

const SignupPage = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [signupSuccess, setSignupSuccess] = useState(false); // State to track signup success
  const navigate = useNavigate();

  const handleSignup = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const response = await fetch('/api/signup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password }),
      });

      if (response.ok) {
        // Update state to indicate signup success
        setSignupSuccess(true);
        
        // Show message for a short time before redirecting
        setTimeout(() => {
          navigate('/login');
        }, 2000); // Adjust delay as needed
      } else {
        const errorData = await response.json();
        setError(errorData.message || 'An error occurred. Please try again.');
        setSignupSuccess(false); // Ensure state is reset on error
      }
    } catch (error) {
      setError('Network error. Please try again later.');
      setSignupSuccess(false); // Ensure state is reset on network error
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
    <button onClick={() => navigate('/login')}>Login</button>
      <h1>Sign Up</h1>
      <form onSubmit={handleSignup}>
        <div>
          <label htmlFor="username">Username:</label>
          <input
            type="text"
            id="username"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            disabled={signupSuccess} // Disable input on signup success
          />
        </div>
        <div>
          <label htmlFor="password">Password:</label>
          <input
            type="password"
            id="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            disabled={signupSuccess} // Disable input on signup success
          />
        </div>
        <button type="submit" disabled={loading || signupSuccess}>
          {loading ? 'Signing Up...' : 'Sign Up'}
        </button>
        {error && <p>{error}</p>}
        {signupSuccess && <p>Signup successful! Redirecting to login...</p>}
      </form>
    </div>
  );
};

export default SignupPage;

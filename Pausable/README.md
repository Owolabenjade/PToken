# SecureFinEx (SFX) Token Smart Contract
## A Pausable Token with Cross-Contract Recovery System

SecureFinEx (SFX) Token is a secure and recoverable token implementation built using the Clarity smart contract language. It features advanced security measures including contract pausability, multi-signature administration, blacklisting capabilities, rate limiting, and a robust recovery system for compromised accounts.

### Key Features

#### 1. Token Basics
- Total Supply: 1 billion tokens
- Decimal Places: 0 (whole tokens only)
- Standard transfer functionality
- Balance checking capabilities

#### 2. Security Features

##### Pause Mechanism
- Emergency pause/unpause functionality
- Only authorized admins can trigger pause
- All transfers blocked during pause state
- Automatic rate limiting upon unpause

##### Multi-signature Administration
- Multiple administrators can be authorized
- Admin signatures required for critical operations
- Configurable admin system
- Prevents single point of failure in administration

##### Blacklist System
- Ability to blacklist compromised addresses
- Automatic balance snapshot when blacklisting
- Prevents transfers to/from blacklisted addresses
- Admins can remove addresses from blacklist

##### Rate Limiting
- Configurable daily transfer limits
- Automatically activated after contract unpause
- Prevents large-scale token movements
- Adjustable limits by administrators

##### Balance Snapshots
- Automatic balance recording at critical points
- Snapshot creation during blacklisting
- Historical balance verification
- Aids in recovery process

#### 3. Recovery System
- Emergency withdrawal mechanism
- Two-step recovery process (request + approval)
- Safe balance transfer to new addresses
- Admin verification required

### Function Reference

#### Token Operations
```clarity
(transfer (amount uint) (recipient principal))
```
- Transfers tokens between addresses
- Checks: pause state, blacklist, balance, rate limit

```clarity
(get-balance (account principal))
```
- Returns account balance
- Read-only function

#### Administrative Functions
```clarity
(pause-contract)
(unpause-contract)
```
- Control contract pause state
- Admin-only functions

```clarity
(add-admin-signature (admin principal))
(remove-admin-signature (admin principal))
```
- Manage admin permissions
- Only current admins can modify

#### Blacklist Management
```clarity
(add-to-blacklist (address principal))
(remove-from-blacklist (address principal))
```
- Control blacklisted addresses
- Creates balance snapshot when blacklisting

```clarity
(is-blacklisted (address principal))
```
- Check if address is blacklisted
- Read-only function

#### Recovery System
```clarity
(request-recovery (new-address principal))
```
- Request token recovery to new address
- Only available during pause state

```clarity
(approve-recovery (owner principal) (new-address principal))
```
- Admin approval of recovery request
- Transfers balance to new address

#### Rate Limiting
```clarity
(set-rate-limit (active bool) (amount uint))
```
- Configure rate limiting parameters
- Admin-only function

#### Snapshot System
```clarity
(get-snapshot (address principal) (timestamp uint))
```
- Retrieve historical balance snapshots
- Read-only function

### Security Considerations

1. **Emergency Response**
   - Use pause function immediately when suspicious activity is detected
   - Take snapshots before any critical operations
   - Enable rate limiting after security incidents

2. **Administrative Access**
   - Multiple admins should be configured
   - Regular rotation of admin signatures recommended
   - Careful management of admin private keys

3. **Recovery Process**
   - Verify ownership before approving recovery
   - Document recovery requests thoroughly
   - Multiple admin verification recommended

4. **Rate Limiting**
   - Set appropriate limits based on normal usage
   - Adjust limits gradually after incidents
   - Monitor transfer patterns regularly

### Development and Testing

1. **Local Testing**
   ```bash
   # Using Clarinet
   clarinet test
   clarinet console
   ```

2. **Deployment Steps**
   - Deploy contract
   - Initialize admin signatures
   - Configure initial rate limits
   - Test all security features

3. **Recommended Test Cases**
   - Basic transfer functionality
   - Pause/unpause mechanics
   - Admin signature validation
   - Blacklist effectiveness
   - Recovery process
   - Rate limit enforcement

### Error Codes
- `ERR_NOT_AUTHORIZED (u1)`: Unauthorized operation
- `ERR_PAUSED (u2)`: Contract is paused
- `ERR_NOT_PAUSED (u3)`: Contract is not paused
- `ERR_BLACKLISTED (u4)`: Address is blacklisted
- `ERR_RATE_LIMIT (u5)`: Rate limit exceeded
- `ERR_INVALID_AMOUNT (u6)`: Invalid transfer amount

### Best Practices for Usage

1. **Regular Monitoring**
   - Monitor large transfers
   - Track failed transaction patterns
   - Review admin activities
   - Check for unusual patterns

2. **Incident Response**
   - Have emergency response plan ready
   - Document all security incidents
   - Regular security audits
   - Test recovery procedures

3. **Maintenance**
   - Regular security updates
   - Admin key rotation
   - Rate limit adjustments
   - Documentation updates
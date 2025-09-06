;; Title: Regional Governance Contract
;; Version: 1.0.0
;; Summary: Decentralized governance system for regional transportation planning
;; Description: This contract enables regional stakeholders to propose policies,
;;              participate in democratic voting, and manage transportation
;;              governance through transparent decentralized mechanisms.

;; =============================================================================
;; CONSTANTS
;; =============================================================================

;; Proposal statuses
(define-constant STATUS-PENDING u1)
(define-constant STATUS-ACTIVE u2)
(define-constant STATUS-PASSED u3)
(define-constant STATUS-REJECTED u4)
(define-constant STATUS-EXPIRED u5)

;; Vote types
(define-constant VOTE-YES u1)
(define-constant VOTE-NO u2)
(define-constant VOTE-ABSTAIN u3)

;; Region types for transportation planning
(define-constant REGION-URBAN u1)
(define-constant REGION-SUBURBAN u2)
(define-constant REGION-RURAL u3)
(define-constant REGION-INTERSTATE u4)

;; Policy categories
(define-constant POLICY-INFRASTRUCTURE u1)
(define-constant POLICY-FUNDING u2)
(define-constant POLICY-ENVIRONMENTAL u3)
(define-constant POLICY-ACCESSIBILITY u4)
(define-constant POLICY-SAFETY u5)

;; Error codes
(define-constant ERR-UNAUTHORIZED (err u200))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u201))
(define-constant ERR-ALREADY-VOTED (err u202))
(define-constant ERR-VOTING-CLOSED (err u203))
(define-constant ERR-STAKEHOLDER-NOT-REGISTERED (err u204))
(define-constant ERR-INVALID-VOTE-TYPE (err u205))
(define-constant ERR-PROPOSAL-EXPIRED (err u206))
(define-constant ERR-INSUFFICIENT-VOTING-POWER (err u207))
(define-constant ERR-INVALID-POLICY-CATEGORY (err u208))
(define-constant ERR-REGION-NOT-FOUND (err u209))

;; Governance parameters
(define-constant MIN-VOTING-PERIOD u144) ;; ~1 day in blocks
(define-constant MAX-VOTING-PERIOD u1008) ;; ~1 week in blocks
(define-constant QUORUM-THRESHOLD u51) ;; 51% participation required
(define-constant APPROVAL-THRESHOLD u60) ;; 60% yes votes required

;; =============================================================================
;; DATA VARIABLES
;; =============================================================================

;; Governance administrator
(define-data-var governance-admin principal tx-sender)

;; Global counters
(define-data-var proposal-counter uint u0)
(define-data-var region-counter uint u0)
(define-data-var total-registered-stakeholders uint u0)

;; System parameters
(define-data-var min-proposal-deposit uint u1000)
(define-data-var governance-active bool true)

;; =============================================================================
;; DATA MAPS
;; =============================================================================

;; Regional information and metadata
(define-map regions
  { region-id: uint }
  {
    name: (string-ascii 50),
    region-type: uint,
    population: uint,
    area-size: uint,
    transportation-budget: uint,
    coordinator: principal,
    active-policies: uint,
    created-at: uint
  }
)

;; Registered stakeholders with voting power
(define-map stakeholders
  { stakeholder: principal }
  {
    region-id: uint,
    voting-power: uint,
    organization: (string-ascii 100),
    stakeholder-type: (string-ascii 30),
    registration-date: uint,
    total-votes-cast: uint,
    reputation-score: uint
  }
)

;; Transportation policy proposals
(define-map proposals
  { proposal-id: uint }
  {
    proposer: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    policy-category: uint,
    target-region: uint,
    funding-required: uint,
    voting-start: uint,
    voting-end: uint,
    status: uint,
    yes-votes: uint,
    no-votes: uint,
    abstain-votes: uint,
    total-voters: uint,
    execution-block: (optional uint)
  }
)

;; Individual vote records
(define-map votes
  { proposal-id: uint, voter: principal }
  {
    vote-type: uint,
    voting-power: uint,
    cast-at: uint,
    reason: (optional (string-ascii 200))
  }
)

;; Active policies in regions
(define-map active-policies
  { region-id: uint, policy-id: uint }
  {
    policy-title: (string-ascii 100),
    policy-category: uint,
    implementation-date: uint,
    budget-allocated: uint,
    effectiveness-score: uint,
    review-date: uint
  }
)

;; Policy implementation tracking
(define-map policy-implementations
  { policy-id: uint }
  {
    implementing-region: uint,
    start-date: uint,
    expected-completion: uint,
    progress-percentage: uint,
    budget-used: uint,
    milestone-count: uint,
    success-metrics: uint
  }
)

;; =============================================================================
;; PUBLIC FUNCTIONS
;; =============================================================================

;; Register a new region for transportation governance
(define-public (register-region
    (name (string-ascii 50))
    (region-type uint)
    (population uint)
    (area-size uint)
    (initial-budget uint)
  )
  (let
    (
      (new-region-id (+ (var-get region-counter) u1))
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
    ;; Validate region parameters
    (asserts! (and (>= region-type u1) (<= region-type u4)) ERR-INVALID-POLICY-CATEGORY)
    (asserts! (> population u0) ERR-INVALID-POLICY-CATEGORY)
    (asserts! (> area-size u0) ERR-INVALID-POLICY-CATEGORY)
    (asserts! (> (len name) u0) ERR-INVALID-POLICY-CATEGORY)
    
    ;; Store region information
    (map-set regions
      { region-id: new-region-id }
      {
        name: name,
        region-type: region-type,
        population: population,
        area-size: area-size,
        transportation-budget: initial-budget,
        coordinator: tx-sender,
        active-policies: u0,
        created-at: current-time
      }
    )
    
    ;; Update global counter
    (var-set region-counter new-region-id)
    
    (ok new-region-id)
  )
)

;; Register as a stakeholder in regional governance
(define-public (register-stakeholder
    (region-id uint)
    (organization (string-ascii 100))
    (stakeholder-type (string-ascii 30))
    (initial-voting-power uint)
  )
  (let
    (
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
    ;; Validate region exists
    (asserts! (is-some (map-get? regions { region-id: region-id })) ERR-REGION-NOT-FOUND)
    
    ;; Validate not already registered
    (asserts! (is-none (map-get? stakeholders { stakeholder: tx-sender })) ERR-ALREADY-VOTED)
    
    ;; Validate parameters
    (asserts! (> initial-voting-power u0) ERR-INSUFFICIENT-VOTING-POWER)
    (asserts! (> (len organization) u0) ERR-INVALID-POLICY-CATEGORY)
    
    ;; Register stakeholder
    (map-set stakeholders
      { stakeholder: tx-sender }
      {
        region-id: region-id,
        voting-power: initial-voting-power,
        organization: organization,
        stakeholder-type: stakeholder-type,
        registration-date: current-time,
        total-votes-cast: u0,
        reputation-score: u50
      }
    )
    
    ;; Update global counter
    (var-set total-registered-stakeholders (+ (var-get total-registered-stakeholders) u1))
    
    (ok true)
  )
)

;; Submit a new transportation policy proposal
(define-public (submit-proposal
    (title (string-ascii 100))
    (description (string-ascii 500))
    (policy-category uint)
    (target-region uint)
    (funding-required uint)
    (voting-period uint)
  )
  (let
    (
      (proposer-data (unwrap! (map-get? stakeholders { stakeholder: tx-sender }) ERR-STAKEHOLDER-NOT-REGISTERED))
      (new-proposal-id (+ (var-get proposal-counter) u1))
      (voting-start stacks-block-height)
      (voting-end (+ stacks-block-height voting-period))
    )
    ;; Validate proposer is registered stakeholder
    (asserts! (is-some (some proposer-data)) ERR-STAKEHOLDER-NOT-REGISTERED)
    
    ;; Validate proposal parameters
    (asserts! (and (>= policy-category u1) (<= policy-category u5)) ERR-INVALID-POLICY-CATEGORY)
    (asserts! (and (>= voting-period MIN-VOTING-PERIOD) (<= voting-period MAX-VOTING-PERIOD)) ERR-INVALID-POLICY-CATEGORY)
    (asserts! (is-some (map-get? regions { region-id: target-region })) ERR-REGION-NOT-FOUND)
    (asserts! (> (len title) u0) ERR-INVALID-POLICY-CATEGORY)
    
    ;; Store proposal
    (map-set proposals
      { proposal-id: new-proposal-id }
      {
        proposer: tx-sender,
        title: title,
        description: description,
        policy-category: policy-category,
        target-region: target-region,
        funding-required: funding-required,
        voting-start: voting-start,
        voting-end: voting-end,
        status: STATUS-ACTIVE,
        yes-votes: u0,
        no-votes: u0,
        abstain-votes: u0,
        total-voters: u0,
        execution-block: none
      }
    )
    
    ;; Update counter
    (var-set proposal-counter new-proposal-id)
    
    (ok new-proposal-id)
  )
)

;; Cast a vote on a transportation policy proposal
(define-public (cast-vote
    (proposal-id uint)
    (vote-type uint)
    (reason (optional (string-ascii 200)))
  )
  (let
    (
      (proposal-data (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR-PROPOSAL-NOT-FOUND))
      (voter-data (unwrap! (map-get? stakeholders { stakeholder: tx-sender }) ERR-STAKEHOLDER-NOT-REGISTERED))
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
    ;; Validate voting period is active
    (asserts! (<= (get voting-start proposal-data) stacks-block-height) ERR-VOTING-CLOSED)
    (asserts! (> (get voting-end proposal-data) stacks-block-height) ERR-VOTING-CLOSED)
    
    ;; Validate vote type
    (asserts! (and (>= vote-type u1) (<= vote-type u3)) ERR-INVALID-VOTE-TYPE)
    
    ;; Check if already voted
    (asserts! (is-none (map-get? votes { proposal-id: proposal-id, voter: tx-sender })) ERR-ALREADY-VOTED)
    
    ;; Record the vote
    (map-set votes
      { proposal-id: proposal-id, voter: tx-sender }
      {
        vote-type: vote-type,
        voting-power: (get voting-power voter-data),
        cast-at: current-time,
        reason: reason
      }
    )
    
    ;; Update proposal vote tallies
    (let
      (
        (updated-proposal (update-vote-tally proposal-data vote-type (get voting-power voter-data)))
      )
      (map-set proposals
        { proposal-id: proposal-id }
        updated-proposal
      )
    )
    
    ;; Update stakeholder vote count
    (map-set stakeholders
      { stakeholder: tx-sender }
      (merge voter-data { 
        total-votes-cast: (+ (get total-votes-cast voter-data) u1),
        reputation-score: (min u100 (+ (get reputation-score voter-data) u1))
      })
    )
    
    (ok true)
  )
)

;; Execute a passed proposal to activate the policy
(define-public (execute-proposal (proposal-id uint))
  (let
    (
      (proposal-data (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR-PROPOSAL-NOT-FOUND))
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
    ;; Validate proposal has passed and voting is complete
    (asserts! (> stacks-block-height (get voting-end proposal-data)) ERR-VOTING-CLOSED)
    (asserts! (is-eq (get status proposal-data) STATUS-PASSED) ERR-UNAUTHORIZED)
    
    ;; Activate the policy
    (let
      (
        (policy-id proposal-id) ;; Use proposal ID as policy ID
        (target-region (get target-region proposal-data))
      )
      ;; Add to active policies
      (map-set active-policies
        { region-id: target-region, policy-id: policy-id }
        {
          policy-title: (get title proposal-data),
          policy-category: (get policy-category proposal-data),
          implementation-date: current-time,
          budget-allocated: (get funding-required proposal-data),
          effectiveness-score: u0,
          review-date: (+ current-time u52560) ;; Review in ~1 year
        }
      )
      
      ;; Track implementation
      (map-set policy-implementations
        { policy-id: policy-id }
        {
          implementing-region: target-region,
          start-date: current-time,
          expected-completion: (+ current-time u26280), ;; ~6 months
          progress-percentage: u0,
          budget-used: u0,
          milestone-count: u0,
          success-metrics: u0
        }
      )
      
      ;; Update proposal status
      (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal-data { 
          execution-block: (some stacks-block-height)
        })
      )
      
      ;; Update region policy count
      (let
        (
          (region-data (unwrap-panic (map-get? regions { region-id: target-region })))
        )
        (map-set regions
          { region-id: target-region }
          (merge region-data { 
            active-policies: (+ (get active-policies region-data) u1)
          })
        )
      )
      
      (ok policy-id)
    )
  )
)

;; =============================================================================
;; READ-ONLY FUNCTIONS
;; =============================================================================

;; Get comprehensive proposal information
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals { proposal-id: proposal-id })
)

;; Get region information
(define-read-only (get-region (region-id uint))
  (map-get? regions { region-id: region-id })
)

;; Get stakeholder information
(define-read-only (get-stakeholder (stakeholder principal))
  (map-get? stakeholders { stakeholder: stakeholder })
)

;; Get vote information for a specific voter and proposal
(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes { proposal-id: proposal-id, voter: voter })
)

;; Get active policy information
(define-read-only (get-active-policy (region-id uint) (policy-id uint))
  (map-get? active-policies { region-id: region-id, policy-id: policy-id })
)

;; Get policy implementation status
(define-read-only (get-policy-implementation (policy-id uint))
  (map-get? policy-implementations { policy-id: policy-id })
)

;; Calculate current proposal results
(define-read-only (get-proposal-results (proposal-id uint))
  (match (map-get? proposals { proposal-id: proposal-id })
    proposal-data
    (let
      (
        (total-votes (+ (+ (get yes-votes proposal-data) (get no-votes proposal-data)) (get abstain-votes proposal-data)))
        (participation-rate (if (> (var-get total-registered-stakeholders) u0)
                               (/ (* total-votes u100) (var-get total-registered-stakeholders))
                               u0))
        (approval-rate (if (> total-votes u0)
                          (/ (* (get yes-votes proposal-data) u100) total-votes)
                          u0))
      )
      (some {
        total-votes: total-votes,
        participation-rate: participation-rate,
        approval-rate: approval-rate,
        meets-quorum: (>= participation-rate QUORUM-THRESHOLD),
        meets-approval: (>= approval-rate APPROVAL-THRESHOLD),
        would-pass: (and (>= participation-rate QUORUM-THRESHOLD) (>= approval-rate APPROVAL-THRESHOLD))
      })
    )
    none
  )
)

;; Get governance system statistics
(define-read-only (get-governance-stats)
  {
    total-proposals: (var-get proposal-counter),
    total-regions: (var-get region-counter),
    total-stakeholders: (var-get total-registered-stakeholders),
    governance-active: (var-get governance-active),
    admin: (var-get governance-admin)
  }
)

;; =============================================================================
;; PRIVATE FUNCTIONS
;; =============================================================================

;; Update proposal vote tallies based on vote type and voting power
(define-private (update-vote-tally (proposal-data (tuple (proposer principal) (title (string-ascii 100)) (description (string-ascii 500)) (policy-category uint) (target-region uint) (funding-required uint) (voting-start uint) (voting-end uint) (status uint) (yes-votes uint) (no-votes uint) (abstain-votes uint) (total-voters uint) (execution-block (optional uint)))) (vote-type uint) (voting-power uint))
  (merge proposal-data {
    yes-votes: (if (is-eq vote-type VOTE-YES) 
                   (+ (get yes-votes proposal-data) voting-power)
                   (get yes-votes proposal-data)),
    no-votes: (if (is-eq vote-type VOTE-NO)
                  (+ (get no-votes proposal-data) voting-power)
                  (get no-votes proposal-data)),
    abstain-votes: (if (is-eq vote-type VOTE-ABSTAIN)
                       (+ (get abstain-votes proposal-data) voting-power)
                       (get abstain-votes proposal-data)),
    total-voters: (+ (get total-voters proposal-data) u1)
  })
)

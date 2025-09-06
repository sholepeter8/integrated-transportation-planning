;; Title: Transportation Coordination Contract
;; Version: 1.0.0
;; Summary: Multi-modal transportation system coordination and optimization
;; Description: This contract manages transportation routes, vehicle assignments,
;;              resource allocation, and optimization scoring for integrated
;;              transportation planning across multiple transport modes.

;; =============================================================================
;; CONSTANTS
;; =============================================================================

;; Transportation modes
(define-constant TRANSPORT-BUS u1)
(define-constant TRANSPORT-TRAIN u2)
(define-constant TRANSPORT-BIKE-SHARE u3)
(define-constant TRANSPORT-WALKING u4)

;; Route statuses
(define-constant STATUS-ACTIVE u1)
(define-constant STATUS-INACTIVE u2)
(define-constant STATUS-MAINTENANCE u3)

;; Error codes
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-ROUTE-NOT-FOUND (err u101))
(define-constant ERR-INVALID-TRANSPORT-MODE (err u102))
(define-constant ERR-INSUFFICIENT-CAPACITY (err u103))
(define-constant ERR-ROUTE-ALREADY-EXISTS (err u104))
(define-constant ERR-INVALID-OPTIMIZATION-PARAMS (err u105))
(define-constant ERR-VEHICLE-NOT-AVAILABLE (err u106))

;; Maximum values for validation
(define-constant MAX-CAPACITY u10000)
(define-constant MAX-DISTANCE u1000000)
(define-constant MAX-OPTIMIZATION-SCORE u100)

;; =============================================================================
;; DATA VARIABLES
;; =============================================================================

;; Contract owner for administrative functions
(define-data-var contract-owner principal tx-sender)

;; Global route counter for unique IDs
(define-data-var route-counter uint u0)

;; System-wide optimization metrics
(define-data-var total-system-capacity uint u0)
(define-data-var total-allocated-capacity uint u0)

;; =============================================================================
;; DATA MAPS
;; =============================================================================

;; Route information storage
;; Maps route-id to comprehensive route data
(define-map routes
  { route-id: uint }
  {
    creator: principal,
    transport-mode: uint,
    origin: (string-ascii 50),
    destination: (string-ascii 50),
    capacity: uint,
    allocated-capacity: uint,
    distance: uint,
    status: uint,
    optimization-score: uint,
    created-at: uint,
    updated-at: uint
  }
)

;; Vehicle assignments to routes
;; Maps vehicle-id to route assignment data
(define-map vehicle-assignments
  { vehicle-id: (string-ascii 20) }
  {
    route-id: uint,
    capacity-contribution: uint,
    assigned-at: uint,
    status: uint
  }
)

;; Resource allocation tracking
;; Maps route-id to resource allocation details
(define-map resource-allocations
  { route-id: uint }
  {
    allocated-vehicles: uint,
    fuel-allocation: uint,
    maintenance-priority: uint,
    efficiency-rating: uint
  }
)

;; Route optimization metrics
;; Maps route-id to performance and optimization data
(define-map optimization-metrics
  { route-id: uint }
  {
    demand-score: uint,
    efficiency-score: uint,
    utilization-rate: uint,
    environmental-impact: uint,
    cost-efficiency: uint
  }
)

;; =============================================================================
;; PUBLIC FUNCTIONS
;; =============================================================================

;; Create a new transportation route with comprehensive parameters
(define-public (create-route 
    (transport-mode uint)
    (origin (string-ascii 50))
    (destination (string-ascii 50))
    (capacity uint)
    (distance uint)
  )
  (let 
    (
      (new-route-id (+ (var-get route-counter) u1))
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
    ;; Validate input parameters
    (asserts! (and (>= transport-mode u1) (<= transport-mode u4)) ERR-INVALID-TRANSPORT-MODE)
    (asserts! (and (> capacity u0) (<= capacity MAX-CAPACITY)) ERR-INSUFFICIENT-CAPACITY)
    (asserts! (and (> distance u0) (<= distance MAX-DISTANCE)) ERR-INVALID-OPTIMIZATION-PARAMS)
    (asserts! (> (len origin) u0) ERR-INVALID-OPTIMIZATION-PARAMS)
    (asserts! (> (len destination) u0) ERR-INVALID-OPTIMIZATION-PARAMS)
    
    ;; Check if route already exists with same parameters
    (asserts! (is-none (get-route-by-params transport-mode origin destination)) ERR-ROUTE-ALREADY-EXISTS)
    
    ;; Store route information
    (map-set routes
      { route-id: new-route-id }
      {
        creator: tx-sender,
        transport-mode: transport-mode,
        origin: origin,
        destination: destination,
        capacity: capacity,
        allocated-capacity: u0,
        distance: distance,
        status: STATUS-ACTIVE,
        optimization-score: u0,
        created-at: current-time,
        updated-at: current-time
      }
    )
    
    ;; Initialize optimization metrics
    (map-set optimization-metrics
      { route-id: new-route-id }
      {
        demand-score: u0,
        efficiency-score: u0,
        utilization-rate: u0,
        environmental-impact: u0,
        cost-efficiency: u0
      }
    )
    
    ;; Update global counters
    (var-set route-counter new-route-id)
    (var-set total-system-capacity (+ (var-get total-system-capacity) capacity))
    
    (ok new-route-id)
  )
)

;; Assign a vehicle to a specific route
(define-public (assign-vehicle
    (vehicle-id (string-ascii 20))
    (route-id uint)
    (capacity-contribution uint)
  )
  (let
    (
      (route-data (unwrap! (map-get? routes { route-id: route-id }) ERR-ROUTE-NOT-FOUND))
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
    ;; Validate vehicle not already assigned
    (asserts! (is-none (map-get? vehicle-assignments { vehicle-id: vehicle-id })) ERR-VEHICLE-NOT-AVAILABLE)
    
    ;; Validate capacity constraints
    (asserts! (> capacity-contribution u0) ERR-INSUFFICIENT-CAPACITY)
    (asserts! (<= (+ (get allocated-capacity route-data) capacity-contribution) (get capacity route-data)) ERR-INSUFFICIENT-CAPACITY)
    
    ;; Create vehicle assignment
    (map-set vehicle-assignments
      { vehicle-id: vehicle-id }
      {
        route-id: route-id,
        capacity-contribution: capacity-contribution,
        assigned-at: current-time,
        status: STATUS-ACTIVE
      }
    )
    
    ;; Update route allocated capacity
    (map-set routes
      { route-id: route-id }
      (merge route-data { 
        allocated-capacity: (+ (get allocated-capacity route-data) capacity-contribution),
        updated-at: current-time
      })
    )
    
    ;; Update global allocation tracking
    (var-set total-allocated-capacity (+ (var-get total-allocated-capacity) capacity-contribution))
    
    (ok true)
  )
)

;; Update route optimization score based on performance metrics
(define-public (update-optimization-score
    (route-id uint)
    (demand-score uint)
    (efficiency-score uint)
    (utilization-rate uint)
  )
  (let
    (
      (route-data (unwrap! (map-get? routes { route-id: route-id }) ERR-ROUTE-NOT-FOUND))
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
    ;; Validate caller is route creator or contract owner
    (asserts! (or (is-eq tx-sender (get creator route-data)) (is-eq tx-sender (var-get contract-owner))) ERR-UNAUTHORIZED)
    
    ;; Validate score parameters
    (asserts! (and (<= demand-score MAX-OPTIMIZATION-SCORE) 
                   (<= efficiency-score MAX-OPTIMIZATION-SCORE)
                   (<= utilization-rate u100)) ERR-INVALID-OPTIMIZATION-PARAMS)
    
    ;; Calculate composite optimization score
    (let
      (
        (composite-score (/ (+ demand-score efficiency-score utilization-rate) u3))
      )
      ;; Update optimization metrics
      (map-set optimization-metrics
        { route-id: route-id }
        {
          demand-score: demand-score,
          efficiency-score: efficiency-score,
          utilization-rate: utilization-rate,
          environmental-impact: (calculate-environmental-impact route-data),
          cost-efficiency: (calculate-cost-efficiency route-data utilization-rate)
        }
      )
      
      ;; Update route optimization score
      (map-set routes
        { route-id: route-id }
        (merge route-data { 
          optimization-score: composite-score,
          updated-at: current-time
        })
      )
      
      (ok composite-score)
    )
  )
)

;; Allocate resources to a route based on priority and demand
(define-public (allocate-resources
    (route-id uint)
    (vehicle-count uint)
    (fuel-allocation uint)
    (maintenance-priority uint)
  )
  (let
    (
      (route-data (unwrap! (map-get? routes { route-id: route-id }) ERR-ROUTE-NOT-FOUND))
    )
    ;; Validate caller authority
    (asserts! (or (is-eq tx-sender (get creator route-data)) (is-eq tx-sender (var-get contract-owner))) ERR-UNAUTHORIZED)
    
    ;; Validate resource parameters
    (asserts! (and (> vehicle-count u0) (> fuel-allocation u0) (<= maintenance-priority u10)) ERR-INVALID-OPTIMIZATION-PARAMS)
    
    ;; Calculate efficiency rating based on resource allocation
    (let
      (
        (efficiency-rating (calculate-resource-efficiency route-data vehicle-count fuel-allocation))
      )
      ;; Store resource allocation
      (map-set resource-allocations
        { route-id: route-id }
        {
          allocated-vehicles: vehicle-count,
          fuel-allocation: fuel-allocation,
          maintenance-priority: maintenance-priority,
          efficiency-rating: efficiency-rating
        }
      )
      
      (ok efficiency-rating)
    )
  )
)

;; =============================================================================
;; READ-ONLY FUNCTIONS
;; =============================================================================

;; Get comprehensive route information by ID
(define-read-only (get-route (route-id uint))
  (map-get? routes { route-id: route-id })
)

;; Get route optimization metrics
(define-read-only (get-optimization-metrics (route-id uint))
  (map-get? optimization-metrics { route-id: route-id })
)

;; Get vehicle assignment information
(define-read-only (get-vehicle-assignment (vehicle-id (string-ascii 20)))
  (map-get? vehicle-assignments { vehicle-id: vehicle-id })
)

;; Get resource allocation for a route
(define-read-only (get-resource-allocation (route-id uint))
  (map-get? resource-allocations { route-id: route-id })
)

;; Get system-wide capacity utilization statistics
(define-read-only (get-system-capacity-stats)
  (let
    (
      (total-capacity (var-get total-system-capacity))
      (allocated-capacity (var-get total-allocated-capacity))
    )
    {
      total-capacity: total-capacity,
      allocated-capacity: allocated-capacity,
      available-capacity: (- total-capacity allocated-capacity),
      utilization-percentage: (if (> total-capacity u0) 
                                  (/ (* allocated-capacity u100) total-capacity)
                                  u0)
    }
  )
)

;; Get current route counter
(define-read-only (get-route-counter)
  (var-get route-counter)
)

;; Get contract owner
(define-read-only (get-contract-owner)
  (var-get contract-owner)
)

;; =============================================================================
;; PRIVATE FUNCTIONS
;; =============================================================================

;; Calculate environmental impact score based on transport mode and distance
(define-private (calculate-environmental-impact (route-data (tuple (creator principal) (transport-mode uint) (origin (string-ascii 50)) (destination (string-ascii 50)) (capacity uint) (allocated-capacity uint) (distance uint) (status uint) (optimization-score uint) (created-at uint) (updated-at uint))))
  (let
    (
      (transport-mode (get transport-mode route-data))
      (distance (get distance route-data))
    )
    ;; Calculate impact based on mode efficiency
    (if (is-eq transport-mode TRANSPORT-WALKING)
        u100  ;; Walking has the best environmental score
        (if (is-eq transport-mode TRANSPORT-BIKE-SHARE)
            u90   ;; Bike sharing is very efficient
            (if (is-eq transport-mode TRANSPORT-TRAIN)
                (- u80 (/ distance u10000))  ;; Train efficiency decreases with distance
                (- u60 (/ distance u5000))   ;; Bus efficiency decreases faster
            )
        )
    )
  )
)

;; Calculate cost efficiency based on utilization and capacity
(define-private (calculate-cost-efficiency (route-data (tuple (creator principal) (transport-mode uint) (origin (string-ascii 50)) (destination (string-ascii 50)) (capacity uint) (allocated-capacity uint) (distance uint) (status uint) (optimization-score uint) (created-at uint) (updated-at uint))) (utilization-rate uint))
  (let
    (
      (capacity (get capacity route-data))
      (allocated (get allocated-capacity route-data))
    )
    ;; Higher utilization and lower distance per capacity unit = better cost efficiency
    (if (> capacity u0)
        (min u100 (+ (* utilization-rate u6/10) (* (/ allocated capacity) u40)))
        u0
    )
  )
)

;; Calculate resource efficiency rating
(define-private (calculate-resource-efficiency (route-data (tuple (creator principal) (transport-mode uint) (origin (string-ascii 50)) (destination (string-ascii 50)) (capacity uint) (allocated-capacity uint) (distance uint) (status uint) (optimization-score uint) (created-at uint) (updated-at uint))) (vehicle-count uint) (fuel-allocation uint))
  (let
    (
      (capacity (get capacity route-data))
      (distance (get distance route-data))
    )
    ;; Calculate efficiency based on vehicles per capacity unit and fuel per distance
    (if (and (> vehicle-count u0) (> distance u0))
        (min u100 (/ (* capacity u100) (* vehicle-count (/ fuel-allocation distance))))
        u0
    )
  )
)

;; Find route by transport parameters (for duplicate checking)
(define-private (get-route-by-params (transport-mode uint) (origin (string-ascii 50)) (destination (string-ascii 50)))
  ;; This is a simplified check - in a production system, you'd iterate through routes
  ;; For now, we'll return none to allow route creation
  none
)

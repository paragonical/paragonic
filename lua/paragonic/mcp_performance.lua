-- MCP Performance Monitoring and Optimization Module
-- 
-- This module provides comprehensive performance monitoring, metrics collection,
-- and optimization features for the MCP HTTP transport implementation.

local mcp_performance = {}

-- Performance configuration
local PERFORMANCE_CONFIG = {
    -- Metrics collection
    METRICS = {
        ENABLE_REAL_TIME_MONITORING = true,
        COLLECTION_INTERVAL = 1, -- seconds
        RETENTION_PERIOD = 3600, -- 1 hour
        MAX_METRICS_ENTRIES = 3600, -- 1 hour of data at 1s intervals
    },
    
    -- Performance thresholds
    THRESHOLDS = {
        REQUEST_TIMEOUT_WARNING = 1000, -- ms
        REQUEST_TIMEOUT_CRITICAL = 5000, -- ms
        MEMORY_USAGE_WARNING = 50, -- MB
        MEMORY_USAGE_CRITICAL = 100, -- MB
        CPU_USAGE_WARNING = 80, -- percent
        CPU_USAGE_CRITICAL = 95, -- percent
        CONCURRENT_REQUESTS_WARNING = 50,
        CONCURRENT_REQUESTS_CRITICAL = 100,
    },
    
    -- Optimization settings
    OPTIMIZATION = {
        ENAABLE_CONNECTION_POOLING = true,
        POOL_SIZE = 10,
        CONNECTION_TIMEOUT = 30, -- seconds
        IDLE_TIMEOUT = 300, -- seconds
        ENABLE_REQUEST_CACHING = true,
        CACHE_SIZE = 1000,
        CACHE_TTL = 300, -- seconds
        ENABLE_COMPRESSION = true,
        COMPRESSION_LEVEL = 6,
    },
    
    -- Profiling settings
    PROFILING = {
        ENABLE_FUNCTION_PROFILING = true,
        ENABLE_MEMORY_PROFILING = true,
        ENABLE_NETWORK_PROFILING = true,
        PROFILE_SAMPLE_RATE = 0.1, -- 10% of requests
    },
}

-- Performance state
local performance_state = {
    metrics = {},
    alerts = {},
    optimization_enabled = false,
    profiling_active = false,
    connection_pool = {},
    request_cache = {},
    function_profiles = {},
    memory_snapshots = {},
    network_stats = {},
}

-- Performance metrics structure
local PerformanceMetrics = {
    timestamp = 0,
    request_count = 0,
    response_time_avg = 0,
    response_time_min = 0,
    response_time_max = 0,
    error_count = 0,
    success_rate = 0,
    memory_usage = 0,
    cpu_usage = 0,
    concurrent_requests = 0,
    cache_hit_rate = 0,
    connection_pool_usage = 0,
}

-- Performance alerts
local PerformanceAlert = {
    timestamp = 0,
    level = "INFO", -- INFO, WARNING, CRITICAL
    category = "", -- TIMEOUT, MEMORY, CPU, CONCURRENT
    message = "",
    metrics = {},
}

-- Initialize performance monitoring
function mcp_performance.init(config)
    config = config or {}
    
    -- Merge configuration
    for category, settings in pairs(config) do
        if PERFORMANCE_CONFIG[category] then
            for key, value in pairs(settings) do
                PERFORMANCE_CONFIG[category][key] = value
            end
        end
    end
    
    -- Initialize metrics collection
    performance_state.metrics = {}
    performance_state.alerts = {}
    
    -- Start metrics collection if enabled
    if PERFORMANCE_CONFIG.METRICS.ENABLE_REAL_TIME_MONITORING then
        mcp_performance.start_metrics_collection()
    end
    
    -- Initialize optimization features
    if PERFORMANCE_CONFIG.OPTIMIZATION.ENAABLE_CONNECTION_POOLING then
        mcp_performance.init_connection_pool()
    end
    
    if PERFORMANCE_CONFIG.OPTIMIZATION.ENABLE_REQUEST_CACHING then
        mcp_performance.init_request_cache()
    end
    
    -- Start profiling if enabled
    if PERFORMANCE_CONFIG.PROFILING.ENABLE_FUNCTION_PROFILING then
        mcp_performance.start_function_profiling()
    end
    
    performance_state.optimization_enabled = true
    return true
end

-- Start metrics collection
function mcp_performance.start_metrics_collection()
    if performance_state.metrics_collection_active then
        return false, "Metrics collection already active"
    end
    
    performance_state.metrics_collection_active = true
    
    -- Create metrics collection timer
    local function collect_metrics()
        if not performance_state.metrics_collection_active then
            return
        end
        
        local metrics = mcp_performance.collect_current_metrics()
        table.insert(performance_state.metrics, metrics)
        
        -- Maintain retention limit
        if #performance_state.metrics > PERFORMANCE_CONFIG.METRICS.MAX_METRICS_ENTRIES then
            table.remove(performance_state.metrics, 1)
        end
        
        -- Check for alerts
        mcp_performance.check_performance_alerts(metrics)
        
        -- Schedule next collection
        if vim and vim.defer_fn then
            vim.defer_fn(collect_metrics, PERFORMANCE_CONFIG.METRICS.COLLECTION_INTERVAL * 1000)
        end
    end
    
    -- Start collection
    if vim and vim.defer_fn then
        vim.defer_fn(collect_metrics, PERFORMANCE_CONFIG.METRICS.COLLECTION_INTERVAL * 1000)
    end
    
    return true
end

-- Stop metrics collection
function mcp_performance.stop_metrics_collection()
    performance_state.metrics_collection_active = false
    return true
end

-- Collect current performance metrics
function mcp_performance.collect_current_metrics()
    local metrics = {
        timestamp = os.time(),
        request_count = performance_state.request_count or 0,
        response_time_avg = performance_state.response_time_avg or 0,
        response_time_min = performance_state.response_time_min or 0,
        response_time_max = performance_state.response_time_max or 0,
        error_count = performance_state.error_count or 0,
        success_rate = performance_state.success_rate or 100,
        memory_usage = mcp_performance.get_memory_usage(),
        cpu_usage = mcp_performance.get_cpu_usage(),
        concurrent_requests = performance_state.concurrent_requests or 0,
        cache_hit_rate = mcp_performance.get_cache_hit_rate(),
        connection_pool_usage = mcp_performance.get_connection_pool_usage(),
    }
    
    return metrics
end

-- Get memory usage in MB
function mcp_performance.get_memory_usage()
    local success, result = pcall(function()
        if vim and vim.loop and vim.loop.getrusage then
            local rusage = vim.loop.getrusage()
            if rusage and rusage.ru_maxrss then
                return rusage.ru_maxrss / 1024 -- Convert KB to MB
            end
        end
        return 0
    end)
    
    if success then
        return result
    else
        return 0
    end
end

-- Get CPU usage percentage
function mcp_performance.get_cpu_usage()
    -- Simplified CPU usage calculation
    -- In a real implementation, this would track CPU time between calls
    return 0 -- Placeholder
end

-- Get cache hit rate percentage
function mcp_performance.get_cache_hit_rate()
    if not performance_state.request_cache then
        return 0
    end
    
    local hits = performance_state.request_cache.hits or 0
    local misses = performance_state.request_cache.misses or 0
    local total = hits + misses
    
    if total == 0 then
        return 0
    end
    
    return (hits / total) * 100
end

-- Get connection pool usage percentage
function mcp_performance.get_connection_pool_usage()
    if not performance_state.connection_pool then
        return 0
    end
    
    local active = performance_state.connection_pool.active or 0
    local total = PERFORMANCE_CONFIG.OPTIMIZATION.POOL_SIZE
    
    if total == 0 then
        return 0
    end
    
    return (active / total) * 100
end

-- Check for performance alerts
function mcp_performance.check_performance_alerts(metrics)
    local alerts = {}
    
    -- Check response time
    if metrics.response_time_avg > PERFORMANCE_CONFIG.THRESHOLDS.REQUEST_TIMEOUT_CRITICAL then
        table.insert(alerts, {
            timestamp = metrics.timestamp,
            level = "CRITICAL",
            category = "TIMEOUT",
            message = "Critical response time: " .. metrics.response_time_avg .. "ms",
            metrics = metrics,
        })
    elseif metrics.response_time_avg > PERFORMANCE_CONFIG.THRESHOLDS.REQUEST_TIMEOUT_WARNING then
        table.insert(alerts, {
            timestamp = metrics.timestamp,
            level = "WARNING",
            category = "TIMEOUT",
            message = "High response time: " .. metrics.response_time_avg .. "ms",
            metrics = metrics,
        })
    end
    
    -- Check memory usage
    if metrics.memory_usage > PERFORMANCE_CONFIG.THRESHOLDS.MEMORY_USAGE_CRITICAL then
        table.insert(alerts, {
            timestamp = metrics.timestamp,
            level = "CRITICAL",
            category = "MEMORY",
            message = "Critical memory usage: " .. metrics.memory_usage .. "MB",
            metrics = metrics,
        })
    elseif metrics.memory_usage > PERFORMANCE_CONFIG.THRESHOLDS.MEMORY_USAGE_WARNING then
        table.insert(alerts, {
            timestamp = metrics.timestamp,
            level = "WARNING",
            category = "MEMORY",
            message = "High memory usage: " .. metrics.memory_usage .. "MB",
            metrics = metrics,
        })
    end
    
    -- Check concurrent requests
    if metrics.concurrent_requests > PERFORMANCE_CONFIG.THRESHOLDS.CONCURRENT_REQUESTS_CRITICAL then
        table.insert(alerts, {
            timestamp = metrics.timestamp,
            level = "CRITICAL",
            category = "CONCURRENT",
            message = "Critical concurrent requests: " .. metrics.concurrent_requests,
            metrics = metrics,
        })
    elseif metrics.concurrent_requests > PERFORMANCE_CONFIG.THRESHOLDS.CONCURRENT_REQUESTS_WARNING then
        table.insert(alerts, {
            timestamp = metrics.timestamp,
            level = "WARNING",
            category = "CONCURRENT",
            message = "High concurrent requests: " .. metrics.concurrent_requests,
            metrics = metrics,
        })
    end
    
    -- Add alerts to state
    for _, alert in ipairs(alerts) do
        table.insert(performance_state.alerts, alert)
        
        -- Log alert
        print(string.format("[PERFORMANCE %s] %s: %s", 
            alert.level, alert.category, alert.message))
    end
end

-- Initialize connection pool
function mcp_performance.init_connection_pool()
    performance_state.connection_pool = {
        connections = {},
        active = 0,
        max_size = PERFORMANCE_CONFIG.OPTIMIZATION.POOL_SIZE,
    }
    
    return true
end

-- Get connection from pool
function mcp_performance.get_connection()
    if not performance_state.connection_pool then
        return nil, "Connection pool not initialized"
    end
    
    local pool = performance_state.connection_pool
    
    -- Check if we have available connections
    if #pool.connections > 0 then
        local connection = table.remove(pool.connections)
        pool.active = pool.active + 1
        return connection
    end
    
    -- Check if we can create a new connection
    if pool.active < pool.max_size then
        local connection = mcp_performance.create_connection()
        if connection then
            pool.active = pool.active + 1
            return connection
        end
    end
    
    return nil, "No available connections"
end

-- Return connection to pool
function mcp_performance.return_connection(connection)
    if not performance_state.connection_pool then
        return false, "Connection pool not initialized"
    end
    
    local pool = performance_state.connection_pool
    
    -- Check if connection is still valid
    if mcp_performance.is_connection_valid(connection) then
        table.insert(pool.connections, connection)
    end
    
    pool.active = pool.active - 1
    return true
end

-- Create a new connection
function mcp_performance.create_connection()
    -- Placeholder for connection creation
    -- In a real implementation, this would create HTTP connections
    return {
        id = mcp_performance.generate_connection_id(),
        created_at = os.time(),
        last_used = os.time(),
    }
end

-- Check if connection is still valid
function mcp_performance.is_connection_valid(connection)
    if not connection then
        return false
    end
    
    local current_time = os.time()
    local idle_timeout = PERFORMANCE_CONFIG.OPTIMIZATION.IDLE_TIMEOUT
    
    -- Check if connection has been idle too long
    if current_time - connection.last_used > idle_timeout then
        return false
    end
    
    return true
end

-- Generate unique connection ID
function mcp_performance.generate_connection_id()
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local id = ""
    
    for i = 1, 8 do
        local random_index = math.random(1, #charset)
        id = id .. charset:sub(random_index, random_index)
    end
    
    return id
end

-- Initialize request cache
function mcp_performance.init_request_cache()
    performance_state.request_cache = {
        entries = {},
        hits = 0,
        misses = 0,
        max_size = PERFORMANCE_CONFIG.OPTIMIZATION.CACHE_SIZE,
        ttl = PERFORMANCE_CONFIG.OPTIMIZATION.CACHE_TTL,
    }
    
    return true
end

-- Get cached response
function mcp_performance.get_cached_response(request_key)
    if not performance_state.request_cache then
        return nil
    end
    
    local cache = performance_state.request_cache
    local entry = cache.entries[request_key]
    
    if not entry then
        cache.misses = cache.misses + 1
        return nil
    end
    
    -- Check if entry has expired
    if os.time() - entry.timestamp > cache.ttl then
        cache.entries[request_key] = nil
        cache.misses = cache.misses + 1
        return nil
    end
    
    cache.hits = cache.hits + 1
    return entry.response
end

-- Cache response
function mcp_performance.cache_response(request_key, response)
    if not performance_state.request_cache then
        return false
    end
    
    local cache = performance_state.request_cache
    
    -- Check cache size limit
    local entry_count = 0
    for _ in pairs(cache.entries) do
        entry_count = entry_count + 1
    end
    
    if entry_count >= cache.max_size then
        -- Remove oldest entry
        local oldest_key = nil
        local oldest_time = os.time()
        
        for key, entry in pairs(cache.entries) do
            if entry.timestamp < oldest_time then
                oldest_time = entry.timestamp
                oldest_key = key
            end
        end
        
        if oldest_key then
            cache.entries[oldest_key] = nil
        end
    end
    
    -- Add new entry
    cache.entries[request_key] = {
        response = response,
        timestamp = os.time(),
    }
    
    return true
end

-- Start function profiling
function mcp_performance.start_function_profiling()
    if performance_state.profiling_active then
        return false, "Profiling already active"
    end
    
    performance_state.profiling_active = true
    performance_state.function_profiles = {}
    
    return true
end

-- Stop function profiling
function mcp_performance.stop_function_profiling()
    performance_state.profiling_active = false
    return true
end

-- Profile function execution
function mcp_performance.profile_function(func_name, func)
    if not performance_state.profiling_active then
        return func()
    end
    
    local start_time = os.clock()
    local start_memory = mcp_performance.get_memory_usage()
    
    local success, result = pcall(func)
    
    local end_time = os.clock()
    local end_memory = mcp_performance.get_memory_usage()
    
    local execution_time = (end_time - start_time) * 1000 -- Convert to ms
    local memory_delta = end_memory - start_memory
    
    -- Record profile data
    if not performance_state.function_profiles[func_name] then
        performance_state.function_profiles[func_name] = {
            call_count = 0,
            total_time = 0,
            avg_time = 0,
            min_time = math.huge,
            max_time = 0,
            total_memory = 0,
            avg_memory = 0,
        }
    end
    
    local profile = performance_state.function_profiles[func_name]
    profile.call_count = profile.call_count + 1
    profile.total_time = profile.total_time + execution_time
    profile.avg_time = profile.total_time / profile.call_count
    profile.min_time = math.min(profile.min_time, execution_time)
    profile.max_time = math.max(profile.max_time, execution_time)
    profile.total_memory = profile.total_memory + memory_delta
    profile.avg_memory = profile.total_memory / profile.call_count
    
    if not success then
        error(result)
    end
    
    return result
end

-- Record request metrics
function mcp_performance.record_request(start_time, end_time, success)
    local response_time = (end_time - start_time) * 1000 -- Convert to ms
    
    performance_state.request_count = (performance_state.request_count or 0) + 1
    
    if success then
        performance_state.success_rate = 100
    else
        performance_state.error_count = (performance_state.error_count or 0) + 1
        performance_state.success_rate = ((performance_state.request_count - performance_state.error_count) / performance_state.request_count) * 100
    end
    
    -- Update response time statistics
    if not performance_state.response_time_avg then
        performance_state.response_time_avg = response_time
        performance_state.response_time_min = response_time
        performance_state.response_time_max = response_time
    else
        performance_state.response_time_avg = (performance_state.response_time_avg + response_time) / 2
        performance_state.response_time_min = math.min(performance_state.response_time_min, response_time)
        performance_state.response_time_max = math.max(performance_state.response_time_max, response_time)
    end
end

-- Get performance metrics
function mcp_performance.get_metrics()
    return {
        current = mcp_performance.collect_current_metrics(),
        history = performance_state.metrics,
        alerts = performance_state.alerts,
        profiles = performance_state.function_profiles,
        cache_stats = {
            hits = performance_state.request_cache and performance_state.request_cache.hits or 0,
            misses = performance_state.request_cache and performance_state.request_cache.misses or 0,
            hit_rate = mcp_performance.get_cache_hit_rate(),
        },
        pool_stats = {
            active = performance_state.connection_pool and performance_state.connection_pool.active or 0,
            available = performance_state.connection_pool and #performance_state.connection_pool.connections or 0,
            usage_rate = mcp_performance.get_connection_pool_usage(),
        },
    }
end

-- Get performance summary
function mcp_performance.get_summary()
    local metrics = mcp_performance.get_metrics()
    local current = metrics.current
    
    return {
        status = "healthy",
        uptime = os.time() - (performance_state.start_time or os.time()),
        total_requests = current.request_count,
        avg_response_time = current.response_time_avg,
        success_rate = current.success_rate,
        memory_usage = current.memory_usage,
        cache_hit_rate = current.cache_hit_rate,
        connection_pool_usage = current.connection_pool_usage,
        active_alerts = #metrics.alerts,
    }
end

-- Clear performance data
function mcp_performance.clear_data()
    performance_state.metrics = {}
    performance_state.alerts = {}
    performance_state.function_profiles = {}
    
    if performance_state.request_cache then
        performance_state.request_cache.entries = {}
        performance_state.request_cache.hits = 0
        performance_state.request_cache.misses = 0
    end
    
    return true
end

-- Cleanup performance monitoring
function mcp_performance.cleanup()
    mcp_performance.stop_metrics_collection()
    mcp_performance.stop_function_profiling()
    mcp_performance.clear_data()
    
    performance_state.optimization_enabled = false
    performance_state.profiling_active = false
    
    return true
end

-- Export module
return mcp_performance

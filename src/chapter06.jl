"""
    eulerivp(dudt,tspan,u0,n)

Apply Euler's method to solve the IVP u'=`dudt`(u,t) over the interval `tspan` with
u(`tspan[1]`)=`u0`, using `n` subintervals/steps. Return vectors of times and solution
values.
"""
function eulerivp(dudt,u0,tspan,p,n)
    a,b = tspan
    h = (b-a)/n
    t = [ a + i*h for i in 0:n ]
    u = zeros(n+1)
    u[1] = u0
    for i in 1:n
      u[i+1] = u[i] + h*dudt(u[i],p,t[i])
    end
    return t,u
end

"""
    euler(dudt,u0,tspan,p,n)

Apply Euler's method to solve the scalar- or vector-valued IVP u'=`dudt`(u,p,t) over the interval `tspan` with u(`tspan[1]`)=`u0`, using `n` subintervals/steps.
"""
function euler(dudt,u0,tspan,p,n)
    # Time discretization.
    a,b = tspan
    h = (b-a)/n
    t = [ a + i*h for i in 0:n ]

    # Initial condition and output setup.
    u = fill(float(u0),n+1)

    # The time stepping iteration.
    for i in 1:n
        u[i+1] = u[i] + h*dudt(u[i],p,t[i])
    end
    return t,u
end

"""
    ie2(dudt,u0,tspan,p,n)

Apply the Improved Euler method to solve the vector-valued IVP u'=`dudt`(u,p,t) over the
interval `tspan` with u(`tspan[1]`)=`u0`, using `n` subintervals/steps. Returns a vector
of times and a vector of solution values/vectors.
"""
function ie2(dudt,u0,tspan,p,n)
    # Time discretization.
    a,b = tspan
    h = (b-a)/n
    t = [ a + i*h for i in 0:n ]

    # Initialize output.
    u = fill(float(u0),n+1)

    # Time stepping.
    for i in 1:n
        uhalf = u[i] + h/2*dudt(u[i],p,t[i]);
        u[i+1] = u[i] + h*dudt(uhalf,p,t[i]+h/2);
    end
    return t,u
end

"""
    rk4(dudt,u0,tspan,p,n)

Apply "the" Runge-Kutta 4th order method to solve the vector-valued IVP u'=`dudt`(u,p,t)
over the interval `tspan` with u(`tspan[1]`)=`u0`, using `n` subintervals/steps.
Return a vector of times and a vector of solution values/vectors.
"""
function rk4(dudt,u0,tspan,p,n)
    # Time discretization.
    a,b = tspan
    h = (b-a)/n
    t = [ a + i*h for i in 0:n ]

    # Initialize output.
    u = fill(float(u0),n+1)

    # Time stepping.
    for i in 1:n
        k1 = h*dudt( u[i],      p, t[i]     )
        k2 = h*dudt( u[i]+k1/2, p, t[i]+h/2 )
        k3 = h*dudt( u[i]+k2/2, p, t[i]+h/2 )
        k4 = h*dudt( u[i]+k3,   p, t[i]+h   )
        u[i+1] = u[i] + (k1 + 2*(k2 + k3) + k4)/6
    end
    return t,u
end

"""
    rk23(dudt,u0,tspan,p,tol)

Apply adaptive embedded RK formula to solve the vector-valued IVP u'=`dudt`(u,p,t)
over the interval `tspan` with u(`tspan[1]`)=`u0`, with error tolerance `tol`.
Return a vector of times and a vector of solution values/vectors.
"""
function rk23(dudt,u0,tspan,p,tol)
    # Initialize for the first time step.
    t = [float(tspan[1])]
    u = [float(u0)];   i = 1;
    h = 0.5*tol^(1/3)
    s1 = dudt(u0,p,t[1])

    # Time stepping.
    while t[i] < tspan[2]
        # Detect underflow of the step size.
        if t[i]+h == t[i]
            @warn "Stepsize too small near t=$(t[i])"
            break  # quit time stepping loop
        end

        # New RK stages.
        s2 = dudt( u[i]+(h/2)*s1,   p, t[i]+h/2   )
        s3 = dudt( u[i]+(3*h/4)*s2, p, t[i]+3*h/4 )
        unew2 = u[i] + h*(2*s1 + 3*s2 + 4*s3)/9   # 2rd order solution
        s4 = dudt( unew2, p, t[i]+h )
        err = h*(-5*s1/72 + s2/12 + s3/9 - s4/8)    # 2nd/3rd order difference
        E = norm(err,Inf)                           # error estimate
        maxerr = tol*(1 + norm(u[i],Inf))         # relative/absolute blend

        # Accept the proposed step?
        if E < maxerr     # yes
            push!(t,t[i]+h)
            push!(u,unew2)
            i += 1
            s1 = s4       # use FSAL property
        end

        # Adjust step size.
        q = 0.8*(maxerr/E)^(1/3)       # conservative optimal step factor
        q = min(q,4)                   # limit stepsize growth
        h = min(q*h,tspan[2]-t[i])     # don't step past the end
    end
    return t,u
end

"""
    ab4(dudt,u0,tspan,p,n)

Apply the Adams-Bashforth 4th order method to solve the vector-valued IVP u'=`dudt`(u,p,t)
over the interval `tspan` with u(`tspan[1]`)=`u0`, using `n` subintervals/steps.
"""
function ab4(dudt,u0,tspan,p,n)
    # Time discretization.
    a,b = tspan
    h = (b-a)/n
    t = [ a + i*h for i in 0:n ]

    # Constants in the AB4 method.
    k = 4;    sigma = [55, -59, 37, -9]/24;

    # Find starting values by RK4.
    u = fill(float(u0),n+1)
    ts,us = rk4(dudt,u0,[a,a+(k-1)*h],p,k-1)
    u[1:k] = us[1:k]

    # Compute history of u' values, from newest to oldest.
    f = [ dudt(u[k-i],p,t[k-i]) for i in 1:k-1  ]

    # Time stepping.
    for i in k:n
      f = [ dudt(u[i],p,t[i]), f[1:k-1]... ]   # new value of du/dt
      u[i+1] = u[i] + h*sum(f[j]*sigma[j] for j in 1:k)       # advance one step
    end
    return t,u
end


"""
    am2(dudt,u0,tspan,p,n)

Apply the Adams-Moulton 2nd order method to solve the vector-valued IVP u'=`dudt`(u,p,t)
over the interval `tspan` with u(`tspan[1]`)=`u0`, using `n` subintervals/steps.
"""
function am2(dudt,u0,tspan,p,n)
    # Time discretization.
    a,b = tspan
    h = (b-a)/n
    t = [ a + i*h for i in 0:n ]

     # Initialize output.
     u = fill(float(u0),n+1)

    # Time stepping.
    for i in 1:n
        # Data that does not depend on the new value.
        known = u[i] + h/2*dudt(u[i],p,t[i])
        # Find a root for the new value.
        F = z -> z .- h/2*dudt(z,p,t[i+1]) .- known
        unew = levenberg(F,known)
        u[i+1] = unew[end]
    end
    return t,u
end

# This version is needed to work with scalar problems using levenberg().
# function am2(dudt,u0::Number,tspan,p,n)
#     f = (x,t) -> [dudt(x[1],t)]
#     t,u = am2(f,tspan,[u0],p,n)
#     u = [u[1] for u=u]
#     return t,u
# end

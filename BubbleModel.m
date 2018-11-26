classdef BubbleModel
    properties
        p_BP0;  % Undeformed bubble positions in bubble frame.
        tris;   % Triangle connectivities.
        T0;     % Bubble tension in N/m.
        normal0_B, K, Aeq, node_areas, node_boundary;
        dVdu; % Derivative of the enclosed volume with respect to u.
        V0, p0;
    end
       
    methods
    
        % Constructor.
        % p_BC: position of the camera frame C in the bubble frame B.
        function this = BubbleModel(p_BP0, tris, T0, V0, p0)
           this.p_BP0 = p_BP0;
           this.tris = tris;
           this.T0 = T0;
           this.V0 = V0;
           this.p0 = p0;
           
           % Pre-compute quantities that do not change.
           [this.normal0_B, this.K, this.Aeq, this.node_areas, this.node_boundary, this.dVdu] = ...
               QP_membrane_solver_preproc(p_BP0, tris, T0, V0, p0);                     
        end
        
        % phi0: Distances from bubble to object. Either negative or close
        % to being negative (object might contact after deformation).
        % H: -dphi/du, a sparse matrix with as many rows as entries in phi0
        % and as many columns as number of unkknows (number of mesh nodes).
        function [u, pr, pv, p_BP, Hmean, lambda] = ComputeSolution(this, phi0, H, Hj)
            [u, pv, p_BP, lambda] = QP_membrane_solver(...
                this.p_BP0, this.tris, this.T0, ...
                this.normal0_B, this.K, this.Aeq, ...
                phi0, H);

            npoints = size(this.p_BP0, 1);
            %u = x(1:npoints);
            %pv = x(npoints+1);
            pi = lambda.ineqlin; % KKT multipliers (sparse).
            pr = zeros(npoints, 1);
            pr(Hj) = pi./ this.node_areas(Hj);
            
            %F = this.K * u; % rhs.
            %pr = F ./ this.node_areas; % Actually F = M * p, with M the mass matrix.
            
            % Estimate mean curvature from Lapace's equation: Δp = 2⋅T0⋅H.
            % WARNING: This is not quite the curvature, since when u = 0 then H = 0
            % which is not true.
            Hmean = pr/this.T0/2;
        end
        
        
    
    end % End of methods section.
    
end
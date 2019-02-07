function create_trial_orders_euler(pairs, min_rep, tp)
repetitions = ceil(min_rep/(pairs-1));
total_rep = repetitions * (pairs-1);
edges = ones(pairs)*repetitions.*~eye(pairs);
start = Randi(pairs);
tour = [];
find_tour(start);

if(tp < 1) %when within-TP is lower than one
    num_splits = floor(total_rep*(1-tp));
    splits = zeros(pairs,num_splits);
    breakpoints = [];
    for pair=1:pairs
        splits(pair,:) = randsample(total_rep, num_splits);
        %splits(pair,:) = randsample(1:total_rep, [num_splits 1]); %for r2010
        aux = find(tour==pair);
        breakpoints = [breakpoints aux(splits(pair,:))];
    end
    breakpoints = sort(breakpoints);
    %segment
    segments = {};
    segment_edges = zeros(length(breakpoints));
    segments_inverse = cell(pairs,1);
    segment = struct();
    segment.start = tour(breakpoints(end));
    segment.end = tour(breakpoints(1));
    segment.list = tour([breakpoints(end)+1:length(tour)-1 1:breakpoints(1)]);
    segments{1} = segment;
    segments_inverse{segment.start} = [1];
    last_pos = breakpoints(1);
    
    for index=2:length(breakpoints)
        segment = struct();
        segment.start = tour(last_pos);
        segment.end = tour(breakpoints(index));
        segment.list = tour(last_pos+1:breakpoints(index));
        segments{index} = segment;
        segments_inverse{segment.start} = [segments_inverse{segment.start} index];
        last_pos = breakpoints(index);
    end
    
    %create graph adjacency matrix
    for index=1:length(segments)
        segment_edges(index,:) = ~ismember(1:length(segments),segments_inverse{segments{index}.end});
    end
    
    segment_edges = segment_edges.*~eye(length(segments)); %remove diagonal
    
    segment_tour = [];
    start = Randi(pairs);
    path = find_random_path(start, [start], setdiff(1:length(segments),start));
    
    %reconstruct path and mark deviants
    deviants = [];
    final_order = segments{path(1)}.list;
    for index=2:length(path)
        deviants(length(final_order)) = segments{path(index)}.start;
        final_order = [final_order segments{path(index)}.list];
    end
    save(strcat('orders', filesep, sprintf('order_%ipairs-%irep-%gtp.mat', pairs, total_rep, tp)), 'final_order', 'deviants');
else
    final_order = tour(1:end-1);
    save(strcat('orders', filesep, sprintf('order_%ipairs-%irep-1tp.mat', pairs, total_rep)), 'final_order');
end

    
    function find_tour(node)
        while sum(edges(node,:))>0
            avail_paths = find(edges(node,:));
            selection = avail_paths(randsample(length(avail_paths),1));
            %selection = randsample(avail_paths,[1 1]); % for matlab r2010
            edges(node, selection) = edges(node, selection)-1;
            find_tour(selection);
        end
        tour = [node , tour];
    end

    function path = find_random_path(node, path, tovisit)
        %like find_tour, but used for reordering the segmented path to add noise
        if isempty(tovisit)
            return
        elseif sum(segment_edges(node, tovisit)) == 0
            path = -1;
            return
        else
            adjacent = intersect(find(segment_edges(node, :)),tovisit);
            adjacent = adjacent(randperm(length(adjacent)));
            for adj=1:length(adjacent)
                selection = adjacent(adj);
                result = find_random_path(selection, [path selection], setdiff(tovisit,selection));
                if result ~= -1
                    path = result;
                    return
                end
            end
            path = -1;
            return
        end
    end

    function TPs = calculateTPs(sti_order)
        num_sti = numel(unique(sti_order));
        joint_freq = zeros(num_sti);
        marg_freq = zeros(num_sti,1);
        marg_freq(sti_order(1)) = 1;
        for ii=2:size(sti_order)
            joint_freq(sti_order(ii-1),sti_order(ii)) = joint_freq(sti_order(ii-1),sti_order(ii))+1;
            marg_freq(sti_order(ii)) = marg_freq(sti_order(ii)) + 1;
        end
        TPs = joint_freq./repmat(marg_freq,[1,num_sti]);
    end
end

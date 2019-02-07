function create_trial_orders_euler_smallblocks(pairs, min_rep, blocks, gens)
%creates exposure pairs order divided in balanced pairs:
% pairs: number of different pairs
% min_rep: minimum number of times each pair appears
% blocks: number of blocks
% gen: number of orders to be generated. The order with smallest count 
%   variance (better balanced across blocks) is saved
repetitions = ceil(min_rep/(pairs-1));
total_rep = repetitions * (pairs-1);
total_length = total_rep*pairs;
block_size = total_length/blocks;
block_idx = ceil((1:total_length) / block_size);
gen_orders = {};
gen_hists = {};
gen_vars = [];
gen_entropy = [];
min_var = Inf;
min_idx = 0;

for gen=1:gens
    gen
    gen_orders{gen} = create_trial_orders(); 
    gen_hists{gen} = histcounts2(gen_orders{gen}, block_idx, [pairs, blocks]);
    gen_vars(gen) = var(reshape(gen_hists{gen},[],1));
    gen_entropy(gen) = entropy(gen_hists{gen}/20);
    if gen_vars(gen) < min_var
        min_var = gen_vars(gen);
        min_idx = gen;
    end
end

final_order = gen_orders{min_idx};
save(strcat(sprintf('order_%ipairs-%irep-%iblocks.mat', pairs, total_rep, blocks)), 'final_order');

    function tour = create_trial_orders()
        edges = ones(pairs)*repetitions.*~eye(pairs);
        start = Randi(pairs);
        tour = [];
        find_tour(start);
        tour = tour(1:end-1);
        
        function find_tour(node)
            while sum(edges(node,:))>0
                avail_paths = find(edges(node,:));
                selection = avail_paths(randsample(length(avail_paths),1));
                edges(node, selection) = edges(node, selection)-1;
                find_tour(selection);
            end
            tour = [node , tour];
        end
    end
end

def report(stats)
  range = stats.keys.minmax
  (range[0][0] .. range[1][0]).each do |year|
    (1 .. 12).each do |month|
      next if year == range[0][0] && month < range[0][1]
      next if year == range[1][0] && month > range[1][1]

      puts [year, month, stats[[year, month]] || 0].join("\t")
    end
  end
end

namespace :usage do
  task :queries => :environment do |t, args|
    stats = {}

    # Query datasets
    QueryDataset.all.pluck(:created_at).each do |d|
      period = [d.year, d.month]
      stats[period] ||= 0
      stats[period]  += 1
    end

    # Individual project references
    # TODO

    # Report
    report(stats)
  end

  task :users => :environment do |t, args|
    stats = {}

    # Users with at least one query dataset
    User.where(id: QueryDataset.all.pluck(:user_id).uniq)
        .pluck(:created_at).each do |d|
      period = [d.year, d.month]
      stats[period] ||= 0
      stats[period]  += 1
    end

    # Report
    report(stats)
  end
end

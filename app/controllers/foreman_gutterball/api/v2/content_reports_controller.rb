module ForemanGutterball
  module Api
    module V2
      class ContentReportsController < ::Katello::Api::V2::ApiController
        before_filter :find_organization, :only => [:system_status, :system_trend, :status_trend]

        api :GET, '/content_reports/system_status', N_('Show the latest subscription status for a list of content ' \
          'hosts that have reported their subscription status during a specified time period. Running this report ' \
          'with minimal parameters will return all status records for all reported content hosts.')
        param :system_id, :identifier, :desc => N_('Filters the results by the given content host UUID.')
        param :organization_id, :identifier, :desc => N_('Organization ID'), :required => true
        param :status, ['valid', 'invalid', 'partial'], :desc => N_('Filter results on content host status.')
        param :on_date, Date, :desc => N_('Date to filter on. If not given, defaults to NOW. Results will be limited ' \
          'to status records that were last reported before or on the given date. ' \
          'Must be a date in the form of YYYY-MM-DD.')
        def system_status
          zomg_reports!('consumer_status')
        end

        api :GET, '/content_reports/system_trend', N_('Show a listing of all subscription status snapshots from ' \
          'content hosts which have reported their subscription status in the specified time period.')
        param :system_id,
          :identifier,
          :desc => N_('Filters the results by the given content host UUID.'),
          :required => true
        param :organization_id, :identifier, :desc => N_('Organization ID'), :required => true
        param :start_date, Date, :desc => N_('Start date. Used in conjunction with end_date. ' \
              'Must be a date in the form of YYYY-MM-DD.')
        param :end_date, Date, :desc => N_('End date. Used in conjunction with start_date. ' \
              'Must be a date in the form of YYYY-MM-DD.')
        param :hours, Integer,
          :desc => N_('Show a trend between HOURS and now. Used independently of start_date/end_date.')
        def system_trend
          zomg_reports!('consumer_trend')
        end

        api :GET, '/content_reports/status_trend', N_('Show the per-day counts of content-hosts, grouped by ' \
          'subscription status, optionally limited to a date range.')
        param :organization_id, :identifier, :desc => N_('Organization ID'), :required => true
        param :start_date, Date, :desc => N_('Start date. Used in conjunction with end_date. ' \
              'Must be a date in the form of YYYY-MM-DD.')
        param :end_date, Date, :desc => N_('End date. Used in conjunction with start_date. ' \
              'Must be a date in the form of YYYY-MM-DD.')
        def status_trend
          zomg_reports!('status_trend')
        end

        private

        def zomg_reports!(report_type)
          task = async_task(::Actions::ForemanGutterball::ContentReports::Report, report_type, param_filter(params))
          respond_for_async :resource => task
        end

        def param_filter(params)
          send("#{params[:action]}_filter", params)
        end

        def system_status_filter(params)
          params.permit(*%w(system_id organization_id status on_date))
        end

        def system_trend_filter(params)
          params.permit(*%w(system_id organization_id hours start_date end_date))
        end

        def status_trend_filter(params)
          params.permit(*%w(organization_id start_date end_date))
        end
      end
    end
  end
end

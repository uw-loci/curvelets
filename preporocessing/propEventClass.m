classdef propEventClass < handle
   % Class to observe property events
   properties (GetObservable,SetObservable)
      PropOne string = "default"
   end
   methods
      function obj = propEventClass
%          addlistener(obj,'PropOne','PreGet',@propEventHandler);
%          addlistener(obj,'PropOne','PostSet',@propEventHandler);
         addlistener(obj,'PropOne','PreGet',@(src,evnt)propEventHandler(obj,src,evnt));
         addlistener(obj,'PropOne','PostSet',@(src,evnt)propEventHandler(obj,src,evnt));
      end
   end
   methods %(Static)
      function propEventHandler(~,~,eventData)
          switch eventData.Source.Name % Get property name
              case 'PropOne'
                  switch eventData.EventName % Get the event name
                      case 'PreGet'
                          fprintf('%s\n','***PreGet triggered***')
                      case 'PostSet'
                          fprintf('%s\n','***PostSet triggered***')
                          disp(eventData.AffectedObject.(eventData.Source.Name));
                  end
          end
      end
   end
end
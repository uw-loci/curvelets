function propEventHandler(~,eventData)
   switch eventData.Source.Name % Get property name
      case 'Prop1'
         switch eventData.EventName % Get the event name
            case 'PreGet'
               fprintf('%s\n','***PreGet triggered***')
            case 'PostSet'
               fprintf('%s\n','***PostSet triggered***')
               disp(eventData.AffectedObject.(eventData.Source.Name));
         end
   end
end
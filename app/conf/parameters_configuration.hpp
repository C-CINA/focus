
#ifndef CONF_USER_PARAMETERS_HPP
#define CONF_USER_PARAMETERS_HPP

#include <iostream>

#include <QSettings>
#include <QVector>
#include <QString>
#include <QStringList>
#include <QHash>
#include <QFile>

#include "repositories/path_repo.hpp"
#include "repositories/project_repo.hpp"

#include "old_config_porter.hpp"
#include "project_preferences.hpp"

namespace tdx {
    
    namespace app {
        
        namespace conf {
            
            class ParametersConfiguration : public QSettings {

            public:
                
                ParametersConfiguration(const QString& confFile) 
                : QSettings(confFile, QSettings::Format::IniFormat) {}
                
                void setCurrentParameter(const QString& param) {
                    currParameter_ = param;
                }
                
                bool currentParameterPropertyExists(const QString& prop) {
                    bool yup = false;
                    beginGroup("parameters");
                    beginGroup(currParameter_);
                    if(contains(prop)) yup = true;
                    endGroup();
                    endGroup();
                    return yup;
                }
                
                QString currentParameterProperty(const QString& prop) {
                    beginGroup("parameters");
                    beginGroup(currParameter_);
                    QString val = value(prop).toString();
                    endGroup();
                    endGroup();
                    return val;
                }
                
                void setCurrentParameterProperty(const QString& prop, const QString& val) {
                    beginGroup("parameters");
                    beginGroup(currParameter_);
                    setValue(prop, val);
                    endGroup();
                    endGroup();
                }
                
            private:
                
                QString currParameter_;
            };
            
            class GlobalParameterConfiguration : public ParametersConfiguration {
                
            public:
                GlobalParameterConfiguration() 
                : ParametersConfiguration(repo::PathRepo::globalParametersConfFile()){}
                
                void syncGlobalParameters() {
                    OldConfigPorter::portConfigFile(repo::PathRepo::configDir().absolutePath() + "/2dx_master.cfg",
                                                    repo::PathRepo::globalParametersConfFile());
                }
                
                QStringList parameters() {
                    beginGroup("parameters");
                    QStringList pars = childGroups();
                    endGroup();
                    return pars;
                }
                
            };
            
            class ProjectParameterConfiguration : public ParametersConfiguration {
                
            public:
                ProjectParameterConfiguration() 
                : ParametersConfiguration(repo::ProjectRepo::Instance().parameterConfFilePath()){}
                
            };
        }
    }
}

#endif /* PARAMETERS_MANAGER_HPP */

